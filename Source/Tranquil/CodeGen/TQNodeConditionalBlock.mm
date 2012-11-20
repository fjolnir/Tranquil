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
    BasicBlock *startBlock = aBlock.basicBlock;
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
    if(hasElse)
        startBuilder->CreateCondBr(testResult, thenBB, elseBB);
    else
        startBuilder->CreateCondBr(testResult, thenBB, endifBB);

    aBlock.basicBlock = thenBB;
    aBlock.builder = thenBuilder;
    Value *thenVal = NULL;
    BOOL thenBlockWasTerminated = NO;
    for(TQNode *stmt in _ifStatements) {
        thenVal = [stmt generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        thenBB = aBlock.basicBlock; // May have changed
        if(*aoErr)
            return NULL;
        if([stmt isKindOfClass:[TQNodeReturn class]])
            break;
    }
    if(!aBlock.basicBlock->getTerminator())
        aBlock.builder->CreateBr(endifBB);
    else
        thenBlockWasTerminated = YES;
    delete thenBuilder;

    Value *elseVal = ConstantPointerNull::get(aProgram.llInt8PtrTy);
    BOOL elseBlockWasTerminated = NO;
    if(hasElse) {
        aBlock.basicBlock = elseBB;
        aBlock.builder    = elseBuilder;

        for(TQNode *stmt in _elseStatements) {
            elseVal = [stmt generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
            elseBB = aBlock.basicBlock; // May have changed
            if(*aoErr)
                return NULL;
            if([stmt isKindOfClass:[TQNodeReturn class]])
                break;
        }
        if(!aBlock.basicBlock->getTerminator())
            aBlock.builder->CreateBr(endifBB);
        else
            elseBlockWasTerminated = YES;
        delete elseBuilder;
    }

    Value *ret = ConstantPointerNull::get(aProgram.llInt8PtrTy);
    if(!thenBlockWasTerminated || (hasElse && !elseBlockWasTerminated)) {
        PHINode *phi = endifBuilder->CreatePHI(aProgram.llInt8PtrTy, !thenBlockWasTerminated + 1);
        if(!thenBlockWasTerminated)
            phi->addIncoming(thenVal, thenBB);
        if(hasElse && !elseBlockWasTerminated)
            phi->addIncoming(elseVal, elseBB);
        else
            phi->addIncoming(ConstantPointerNull::get(aProgram.llInt8PtrTy), startBlock);
        ret = phi;
    }

    // Make the parent block continue from the end of the statement
    aBlock.basicBlock = endifBB;
    aBlock.builder = endifBuilder;
    return ret;
}
@end

@implementation TQNodeUnlessBlock
+ (TQNodeUnlessBlock *)nodeWithCondition:(TQNode *)aCond
                            ifStatements:(NSMutableArray *)ifStmt
                          elseStatements:(NSMutableArray *)elseStmt
{
    return (TQNodeUnlessBlock *)[super nodeWithCondition:aCond ifStatements:ifStmt elseStatements:elseStmt];
}
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
@synthesize ifExpr=_ifExpr, elseExpr=_elseExpr, isNegated=_isNegated;

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

// TODO: Merge this with IfBlock, now that it also returns a value?
- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    assert(_ifExpr || _elseExpr);

    BasicBlock *thenBB = NULL;
    BasicBlock *elseBB = NULL;
    if(_ifExpr)
        thenBB = BasicBlock::Create(aProgram.llModule->getContext(), "ternThen", aBlock.function);
    if(_elseExpr)
        elseBB = BasicBlock::Create(aProgram.llModule->getContext(), "ternElse", aBlock.function);
    BasicBlock *contBB = BasicBlock::Create(aProgram.llModule->getContext(), "ternEnd", aBlock.function);

    Value *cond = [self.condition generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    Value *test;
    if(!_isNegated)
        test = aBlock.builder->CreateICmpNE(cond, ConstantPointerNull::get(aProgram.llInt8PtrTy), "ternTest");
    else
        test = aBlock.builder->CreateICmpEQ(cond, ConstantPointerNull::get(aProgram.llInt8PtrTy), "ternTest");
    BasicBlock *condBB = aBlock.basicBlock;
    IRBuilder<> *condBuilder = aBlock.builder;

    Value *thenVal;
    if(thenBB) {
        IRBuilder<> thenBuilder(thenBB);
        aBlock.basicBlock = thenBB;
        aBlock.builder = &thenBuilder;
        thenVal = [_ifExpr generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        thenBB = aBlock.basicBlock; // May have changed
        aBlock.builder->CreateBr(contBB);
    } else {
        thenVal = cond;
        thenBB = contBB;
    }

    Value *elseVal;
    if(elseBB) {
        IRBuilder<> elseBuilder(elseBB);
        aBlock.basicBlock = elseBB;
        aBlock.builder = &elseBuilder;
        elseVal = [_elseExpr generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        elseBB = aBlock.basicBlock; // May have changed
        aBlock.builder->CreateBr(contBB);
    } else {
        elseVal = [[TQNodeNil node] generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        elseBB = contBB;
    }

    IRBuilder<> *contBuilder = new IRBuilder<>(contBB);
    aBlock.basicBlock = contBB;
    aBlock.builder    = contBuilder;

    condBuilder->CreateCondBr(test, thenBB, elseBB);

    PHINode *phi = contBuilder->CreatePHI(aProgram.llInt8PtrTy, 2);
    phi->addIncoming(thenVal, _ifExpr   ? thenBB : condBB);
    phi->addIncoming(elseVal, _elseExpr ? elseBB : condBB);

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
