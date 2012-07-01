#import "TQNodeIfBlock.h"
#import "TQProgram.h"
#import "TQNodeVariable.h"


using namespace llvm;

@implementation TQNodeIfBlock
@synthesize condition=_condition, elseBlockStatements=_elseBlockStatements;


+ (TQNodeIfBlock *)node { return (TQNodeIfBlock *)[super node]; }

- (id)init
{
    if(!(self = [super init]))
        return nil;

    // If blocks don't take arguments
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
    NSMutableString *out = [NSMutableString stringWithString:@"<if@ "];
    [out appendFormat:@"(%@)", _condition];
    [out appendString:@" {\n"];

    if(self.statements.count > 0) {
        [out appendString:@"\n"];
        for(TQNode *stmt in self.statements) {
            [out appendFormat:@"\t%@\n", stmt];
        }
    }
    if(_elseBlockStatements.count > 0) {
        [out appendString:@"}\n else {\n"];
        for(TQNode *stmt in _elseBlockStatements) {
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
    if((ref = [self.statements tq_referencesNode:aNode]))
        return ref;
    return nil;
}


#pragma mark - Code generation

- (llvm::Value *)generateTestExpressionInProgram:(TQProgram *)aProgram
                                           block:(TQNodeBlock *)aBlock
                                           value:(llvm::Value *)aValue
{
    return aBlock.builder->CreateICmpNE(aValue, ConstantPointerNull::get(aProgram.llInt8PtrTy), "ifTest");
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
    IRBuilder<> *builder = aBlock.builder;
    Module *mod = aProgram.llModule;

    // Pose as the parent block for the duration of code generation
    self.function = aBlock.function;
    self.autoreleasePool = aBlock.autoreleasePool;

    Value *testExpr = [_condition generateCodeInProgram:aProgram block:aBlock error:aoErr];
    if(*aoErr)
        return NULL;
    Value *testResult = [self generateTestExpressionInProgram:aProgram block:aBlock value:testExpr];

    BOOL hasElse = (_elseBlockStatements.count > 0);

    BasicBlock *thenBB = BasicBlock::Create(mod->getContext(), "then", aBlock.function);
    IRBuilder<> *thenBuilder = NULL;
    BasicBlock *elseBB = NULL;
    IRBuilder<> *elseBuilder = NULL;

    thenBuilder = new IRBuilder<>(thenBB);
    self.basicBlock = thenBB;
    self.builder = thenBuilder;
    for(TQNode *stmt in self.statements) {
        [stmt generateCodeInProgram:aProgram block:self error:aoErr];
        if(*aoErr)
            return NULL;
    }

    if(hasElse) {
        elseBB = BasicBlock::Create(mod->getContext(), "else", aBlock.function);
        elseBuilder = new IRBuilder<>(elseBB);
        self.basicBlock = elseBB;
        self.builder = elseBuilder;
        for(TQNode *stmt in _elseBlockStatements) {
            [stmt generateCodeInProgram:aProgram block:self error:aoErr];
            if(*aoErr)
                return NULL;
        }
    }

    BasicBlock *endifBB = BasicBlock::Create(mod->getContext(), "endif", aBlock.function);
    IRBuilder<> *endifBuilder = new IRBuilder<>(endifBB);

    // If our basic block has been changed that means there was a nested conditional
    // We need to fix it by adding a br pointing to the endif
    if(self.basicBlock != thenBB && self.basicBlock != elseBB) {
        BasicBlock *tailBlock = self.basicBlock;
        IRBuilder<> *tailBuilder = self.builder;

        if(!tailBlock->getTerminator())
            tailBuilder->CreateBr(endifBB);
    }
    if(!thenBB->getTerminator())
        thenBuilder->CreateBr(endifBB);
    if(elseBB && !elseBB->getTerminator())
        elseBuilder->CreateBr(endifBB);

    delete thenBuilder;
    delete elseBuilder;

    builder->CreateCondBr(testResult, thenBB, elseBB ? elseBB : endifBB);

    // Make the parent block continue from the end of the statement
    aBlock.basicBlock = endifBB;
    aBlock.builder = endifBuilder;

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

@implementation TQNodeUnlessBlock
- (llvm::Value *)generateTestExpressionInProgram:(TQProgram *)aProgram
                                           block:(TQNodeBlock *)aBlock
                                           value:(llvm::Value *)aValue
{
    return aBlock.builder->CreateICmpEQ(aValue, ConstantPointerNull::get(aProgram.llInt8PtrTy), "ifTest");
}
@end
