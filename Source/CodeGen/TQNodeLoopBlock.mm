#import "TQNodeLoopBlock.h"
#import "TQProgram.h"
#import "TQNodeVariable.h"
#import "TQNodeReturn.h"

using namespace llvm;

@implementation TQNodeWhileBlock
@synthesize condition=_condition;


+ (TQNodeWhileBlock *)node { return (TQNodeWhileBlock *)[super node]; }

- (id)init
{
    if(!(self = [super init]))
        return nil;

    // Loop blocks don't take arguments
    [[self arguments] removeAllObjects];

    return self;
}

- (void)dealloc
{
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


#pragma mark - Code generation

- (llvm::Value *)generateTestExpressionInProgram:(TQProgram *)aProgram
                                     withBuilder:(IRBuilder<> *)aBuilder
                                           value:(llvm::Value *)aValue
{
    return aBuilder->CreateICmpNE(aValue, ConstantPointerNull::get(aProgram.llInt8PtrTy), "whileTest");
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
    IRBuilder<> *builder = aBlock.builder;
    Module *mod = aProgram.llModule;

    // Pose as the parent block for the duration of code generation
    self.function        = aBlock.function;
    self.autoreleasePool = aBlock.autoreleasePool;
    self.locals          = aBlock.locals;

    BasicBlock *condBB = BasicBlock::Create(mod->getContext(), "loopCond", aBlock.function);
    IRBuilder<> *condBuilder = new IRBuilder<>(condBB);
    aBlock.builder->CreateBr(condBB);

    BasicBlock *loopBB = BasicBlock::Create(mod->getContext(), "loopBody", aBlock.function);
    IRBuilder<> *loopBuilder = new IRBuilder<>(loopBB);
    self.basicBlock = loopBB;
    self.builder = loopBuilder;

    for(TQNode *stmt in self.statements) {
        [stmt generateCodeInProgram:aProgram block:self error:aoErr];
        if(*aoErr)
            return NULL;
        if([stmt isKindOfClass:[TQNodeReturn class]])
            break;
    }

    BasicBlock *endloopBB = BasicBlock::Create(mod->getContext(), "endloop", aBlock.function);
    IRBuilder<> *endloopBuilder = new IRBuilder<>(endloopBB);

    // If our basic block has been changed that means there was a nested conditional/loop
    // We need to fix it by adding a br pointing to the loop condition
    if(self.basicBlock != loopBB) {
        BasicBlock *tailBlock = self.basicBlock;
        IRBuilder<> *tailBuilder = self.builder;

        if(!tailBlock->getTerminator())
            tailBuilder->CreateBr(condBB);
    }
    if(!loopBB->getTerminator())
        loopBuilder->CreateBr(condBB);

    delete loopBuilder;

    // Make the parent block continue from the end of the statement
    aBlock.basicBlock = endloopBB;
    aBlock.builder = endloopBuilder;

    // Generate the condition instructions
    self.basicBlock = condBB;
    self.builder    = condBuilder;
    Value *testExpr = [_condition generateCodeInProgram:aProgram block:self error:aoErr];
    if(*aoErr)
        return NULL;
    Value *testResult = [self generateTestExpressionInProgram:aProgram withBuilder:condBuilder value:testExpr];
    condBuilder->CreateCondBr(testResult, loopBB, endloopBB);

    self.builder = NULL;
    self.function = NULL;

    return testResult;
}


#pragma mark - Unused methods from TQNodeBlock
- (NSString *)signature
{
    return nil;
}
- (BOOL)addArgument:(NSString *)aArgument error:(NSError **)aoError
{
    return NO;
}
- (llvm::Constant *)_generateBlockDescriptorInProgram:(TQProgram *)aProgram
{
    return NULL;
}
- (llvm::Value *)_generateBlockLiteralInProgram:(TQProgram *)aProgram parentBlock:(TQNodeBlock *)aParentBlock
{
    return NULL;
}
- (llvm::Function *)_generateCopyHelperInProgram:(TQProgram *)aProgram
{
    return NULL;
}
- (llvm::Function *)_generateDisposeHelperInProgram:(TQProgram *)aProgram
{
    return NULL;
}
- (llvm::Function *)_generateInvokeInProgram:(TQProgram *)aProgram error:(NSError **)aoErr
{
    return NULL;
}
- (llvm::Type *)_blockDescriptorTypeInProgram:(TQProgram *)aProgram
{
    return NULL;
}
- (llvm::Type *)_genericBlockLiteralTypeInProgram:(TQProgram *)aProgram
{
    return NULL;
}
- (llvm::Type *)_blockLiteralTypeInProgram:(TQProgram *)aProgram
{
    return NULL;
}
- (llvm::Type *)_byRefTypeInProgram:(TQProgram *)aProgram
{
    return NULL;
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
