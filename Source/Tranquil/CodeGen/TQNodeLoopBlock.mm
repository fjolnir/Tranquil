#import "TQNodeLoopBlock.h"
#import "TQNodeConditionalBlock.h"
#import "../Shared/TQDebug.h"
#import "TQProgram.h"
#import "TQNodeVariable.h"
#import "TQNodeReturn.h"
#import <objc/runtime.h>

using namespace llvm;

void * const TQCurrLoopKey = (void*)&TQCurrLoopKey;

@implementation TQNodeWhileBlock
@synthesize condition=_condition, loopStartBlock=_loopStartBlock, loopEndBlock=_loopEndBlock, statements=_statements, cleanupStatements=_cleanupStatements;


+ (TQNodeWhileBlock *)node { return (TQNodeWhileBlock *)[super node]; }
+ (TQNodeWhileBlock *)nodeWithCondition:(TQNode *)aCond statements:(NSMutableArray *)aStmt
{
    TQNodeWhileBlock *ret = [self node];
    ret.condition = aCond;
    ret.statements = aStmt;
    return ret;
}

- (id)init
{
    if(!(self = [super init]))
        return nil;
    _cleanupStatements = [NSMutableArray new];
    _statements = [NSMutableArray new];
    return self;
}

- (void)dealloc
{
    [_statements release];
    [_cleanupStatements release];
    [_condition release];
    [super dealloc];
}

- (NSString *)description
{
    NSMutableString *out = [NSMutableString stringWithString:@"<while@ "];
    [out appendFormat:@"(%@)", _condition];
    [out appendString:@" {\n"];

    if(self.statements.count > 0) {
        [out appendString:@"\n"];
        for(TQNode *stmt in self.statements) {
            [out appendFormat:@"\t%@\n", stmt];
        }
    }
    [out appendString:@"}>"];
    return out;
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    TQNode *ref = nil;

    if((ref = [_condition referencesNode:aNode]))
        return ref;
    else if((ref = [self.statements tq_referencesNode:aNode]))
        return ref;

    return nil;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    aBlock(_condition);
    NSMutableArray *statements = [_statements copy];
    for(TQNode *node in statements) {
        aBlock(node);
    }
    [statements release];
}

#pragma mark - Code generation

- (llvm::Value *)generateTestExpressionInProgram:(TQProgram *)aProgram
                                     withBuilder:(IRBuilder<> *)aBuilder
                                           value:(llvm::Value *)aValue
{
    return aBuilder->CreateICmpNE(aValue, ConstantPointerNull::get(aProgram.llInt8PtrTy), "whileTest");
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    Module *mod = aProgram.llModule;

    BasicBlock *condBB = BasicBlock::Create(mod->getContext(), "loopCond", aBlock.function);
    _loopStartBlock = condBB;
    IRBuilder<> *condBuilder = new IRBuilder<>(condBB);
    aBlock.builder->CreateBr(condBB);

    BasicBlock *loopBB = BasicBlock::Create(mod->getContext(), "loopBody", aBlock.function);
    IRBuilder<> *loopBuilder = new IRBuilder<>(loopBB);
    aBlock.basicBlock = loopBB;
    aBlock.builder = loopBuilder;

    BasicBlock *endloopBB = BasicBlock::Create(mod->getContext(), "endloop", aBlock.function);
    _loopEndBlock = endloopBB;
    IRBuilder<> *endloopBuilder = new IRBuilder<>(endloopBB);


    for(TQNode *stmt in self.statements) {
        // Set the current loop once per iteration in case there is a nested loop which would override it.
        objc_setAssociatedObject(aBlock, TQCurrLoopKey, self, OBJC_ASSOCIATION_ASSIGN);
        [stmt generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        if(*aoErr)
            return NULL;
        if([stmt isKindOfClass:[TQNodeReturn class]])
            break;
    }
    objc_setAssociatedObject(aBlock, TQCurrLoopKey, nil, OBJC_ASSOCIATION_ASSIGN);
    if(!aBlock.basicBlock->getTerminator())
        aBlock.builder->CreateBr(condBB);

    delete loopBuilder;

    // Generate the condition instructions
    aBlock.basicBlock = condBB;
    aBlock.builder    = condBuilder;
    Value *testExpr = [_condition generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    // The condition may have changed the basic block
    condBB      = aBlock.basicBlock;
    condBuilder = aBlock.builder;
    if(*aoErr)
        return NULL;
    Value *testResult = [self generateTestExpressionInProgram:aProgram withBuilder:condBuilder value:testExpr];
    condBuilder->CreateCondBr(testResult, loopBB, endloopBB);

    // Make the parent block continue from the end of the statement
    aBlock.basicBlock = endloopBB;
    aBlock.builder = endloopBuilder;

    return ConstantPointerNull::get(aProgram.llInt8PtrTy);
}

@end

@implementation TQNodeUntilBlock
- (llvm::Value *)generateTestExpressionInProgram:(TQProgram *)aProgram
                                     withBuilder:(IRBuilder<> *)aBuilder
                                           value:(llvm::Value *)aValue
{
    return aBuilder->CreateICmpEQ(aValue, ConstantPointerNull::get(aProgram.llInt8PtrTy), "untilTest");
}
@end

@implementation TQNodeBreak
+ (TQNodeBreak *)node { return (TQNodeBreak *)[super node]; }

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    TQNodeWhileBlock *loop = objc_getAssociatedObject(aBlock, TQCurrLoopKey);
    TQAssertSoft(loop != nil, kTQSyntaxErrorDomain, kTQUnexpectedStatement, NULL, @"break statements can only be used within loops");
    for(TQNode *stmt in loop.cleanupStatements) {
        [stmt generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    }
    return aBlock.builder->CreateBr(loop.loopEndBlock);
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    // Nothing to iterate
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    return [self isEqual:aNode] ? self : nil;
}
@end

@implementation TQNodeSkip
+ (TQNodeSkip *)node { return (TQNodeSkip *)[super node]; }

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    TQNodeWhileBlock *loop = objc_getAssociatedObject(aBlock, TQCurrLoopKey);
    TQAssertSoft(loop != nil, kTQSyntaxErrorDomain, kTQUnexpectedStatement, NULL, @"skip statements can only be used within loops");

    for(TQNode *stmt in loop.cleanupStatements) {
        [stmt generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    }
    aBlock.builder->CreateBr(loop.loopStartBlock);
    return NULL;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    // Nothing to iterate
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    return [self isEqual:aNode] ? self : nil;
}
@end
