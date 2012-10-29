#import "TQNodeConditionalBlock.h"
#import "TQNodeLoopBlock.h"
#import "TQProgram.h"
#import "TQNodeVariable.h"
#import "TQNodeReturn.h"
#import "../Shared/TQDebug.h"
#import "TQNodeOperator.h"
#import "TQNodeNil.h"

using namespace llvm;

@implementation TQNodeIfBlock
@synthesize condition=_condition, ifStatements=_ifStatements, elseStatements=_elseStatements;

+ (TQNodeIfBlock *)node { return (TQNodeIfBlock *)[super node]; }

+ (TQNodeIfBlock *)nodeWithCondition:(TQNode *)aCond
                        ifStatements:(NSMutableArray *)ifStmt
                      elseStatements:(NSMutableArray *)elseStmt
{
    TQNodeIfBlock *ret = [self node];
    ret.condition = aCond;
    ret.ifStatements = ifStmt;
    ret.elseStatements = elseStmt;
    return ret;
}

- (void)dealloc
{
    [_condition release];
    [_ifStatements release];
    [_elseStatements release];
    [super dealloc];
}

- (NSString *)_name
{
    return @"if";
}

- (NSString *)description
{
    NSMutableString *out = [NSMutableString stringWithFormat:@"<%@@ ", [self _name]];
    [out appendFormat:@"(%@)", _condition];
    [out appendString:@" {\n"];

    if(_ifStatements.count > 0) {
        [out appendString:@"\n"];
        for(TQNode *stmt in _ifStatements) {
            [out appendFormat:@"\t%@\n", stmt];
        }
    }
    if(_elseStatements.count > 0) {
        [out appendString:@"}\n else {\n"];
        for(TQNode *stmt in _elseStatements) {
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
    else if((ref = [_ifStatements tq_referencesNode:aNode]))
        return ref;
    else if((ref = [_elseStatements tq_referencesNode:aNode]))
        return ref;

    return nil;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    aBlock(_condition);
    NSMutableArray *statements = [_ifStatements copy];
    for(TQNode *node in statements) {
        aBlock(node);
    }
    [statements release];
    statements = [_elseStatements copy];
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
    return aBuilder->CreateICmpNE(aValue, ConstantPointerNull::get(aProgram.llInt8PtrTy), "ifTest");
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    Module *mod = aProgram.llModule;

    Value *testExpr = [_condition generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    if(*aoErr)
        return NULL;
    Value *testResult = [self generateTestExpressionInProgram:aProgram withBuilder:aBlock.builder value:testExpr];
    IRBuilder<> *startBuilder = aBlock.builder;

    BOOL hasElse = (_elseStatements.count > 0);

    BasicBlock *thenBB = BasicBlock::Create(mod->getContext(), "then", aBlock.function);
    IRBuilder<> *thenBuilder = new IRBuilder<>(thenBB);
    BasicBlock *elseBB = NULL;
    IRBuilder<> *elseBuilder = NULL;
    if(hasElse) {
        elseBB = BasicBlock::Create(mod->getContext(), "else", aBlock.function);
        elseBuilder = new IRBuilder<>(elseBB);
    }

    BasicBlock *endifBB = BasicBlock::Create(mod->getContext(), [[NSString stringWithFormat:@"end%@", [self _name]] UTF8String], aBlock.function);
    IRBuilder<> *endifBuilder = new IRBuilder<>(endifBB);

    aBlock.basicBlock = thenBB;
    aBlock.builder = thenBuilder;
    for(TQNode *stmt in _ifStatements) {
        [stmt generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        if(*aoErr)
            return NULL;
        if([stmt isKindOfClass:[TQNodeReturn class]])
            break;
    }
    if(!aBlock.basicBlock->getTerminator())
        aBlock.builder->CreateBr(endifBB);
    delete thenBuilder;

    if(hasElse) {
        aBlock.basicBlock = elseBB;
        aBlock.builder    = elseBuilder;
        for(TQNode *stmt in _elseStatements) {
            [stmt generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
            if(*aoErr)
                return NULL;
        }
        if(!aBlock.basicBlock->getTerminator())
            aBlock.builder->CreateBr(endifBB);
        delete elseBuilder;
    }
    startBuilder->CreateCondBr(testResult, thenBB, elseBB ? elseBB : endifBB);

    // Make the parent block continue from the end of the statement
    aBlock.basicBlock = endifBB;
    aBlock.builder = endifBuilder;

    return NULL;
}
@end

@implementation TQNodeUnlessBlock
+ (TQNodeUnlessBlock *)node
{
    return (TQNodeUnlessBlock *)[super node];
}

- (llvm::Value *)generateTestExpressionInProgram:(TQProgram *)aProgram
                                     withBuilder:(IRBuilder<> *)aBuilder
                                           value:(llvm::Value *)aValue
{
    return aBuilder->CreateICmpEQ(aValue, ConstantPointerNull::get(aProgram.llInt8PtrTy), "unlessTest");
}
- (NSString *)_name
{
    return @"unless";
}
@end

@implementation TQNodeTernaryOperator
@synthesize ifExpr=_ifExpr, elseExpr=_elseExpr;

+ (TQNodeTernaryOperator *)node
{
    return (TQNodeTernaryOperator *)[super node];
}

+ (TQNodeTernaryOperator *)nodeWithCondition:(TQNode *)aCond ifExpr:(TQNode *)aIfExpr else:(TQNode *)aElseExpr;
{
    TQNodeTernaryOperator *ret = [self node];
    ret.condition = aCond;
    ret.ifExpr = aIfExpr;
    ret.elseExpr = aElseExpr;
    return ret;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    TQNode *elseExpr = _elseExpr ? _elseExpr : [TQNodeNil node];

    BasicBlock *thenBB = BasicBlock::Create(aProgram.llModule->getContext(), "ternThen", aBlock.function);
    BasicBlock *elseBB = BasicBlock::Create(aProgram.llModule->getContext(), "ternElse", aBlock.function);
    BasicBlock *contBB = BasicBlock::Create(aProgram.llModule->getContext(), "ternEnd", aBlock.function);

    Value *cond = [self.condition generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    cond = aBlock.builder->CreateICmpNE(cond, ConstantPointerNull::get(aProgram.llInt8PtrTy), "ternTest");
    aBlock.builder->CreateCondBr(cond, thenBB, elseBB ? elseBB : contBB);

    IRBuilder<> thenBuilder(thenBB);
    aBlock.basicBlock = thenBB;
    aBlock.builder = &thenBuilder;
    Value *thenVal = [_ifExpr generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    thenBB = aBlock.basicBlock; // May have changed
    aBlock.builder->CreateBr(contBB);

    IRBuilder<> elseBuilder(elseBB);
    aBlock.basicBlock = elseBB;
    aBlock.builder = &elseBuilder;
    Value *elseVal = [elseExpr generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    elseBB = aBlock.basicBlock; // May have changed
    aBlock.builder->CreateBr(contBB);

    IRBuilder<> *contBuilder = new IRBuilder<>(contBB);
    aBlock.basicBlock = contBB;
    aBlock.builder    = contBuilder;

    PHINode *phi = contBuilder->CreatePHI(aProgram.llInt8PtrTy, 2);
    phi->addIncoming(thenVal, thenBB);
    phi->addIncoming(elseVal, elseBB);

    return phi;
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    TQNode *ref;
    if((ref = [self.condition referencesNode:aNode]))
        return ref;
    else if((ref = [_ifExpr referencesNode:aNode]))
        return ref;
    return [_elseExpr referencesNode:aNode];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<ternary@ (%@) ? %@ : %@>", self.condition, _ifExpr, _elseExpr];
}
@end
