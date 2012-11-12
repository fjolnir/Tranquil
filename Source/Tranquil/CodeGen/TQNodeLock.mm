#import "TQNodeLock.h"
#import "TQNode+Private.h"
#import "TQProgram.h"
#import "TQNodeOperator.h"
#import "TQNodeLoopBlock.h"
#import "TQNodeCustom.h"
#import <objc/runtime.h>

using namespace llvm;

@implementation TQNodeLock
@synthesize condition=_condition, statements=_statements;

+ (TQNodeLock *)nodeWithCondition:(TQNode *)aCond
{
    TQNodeLock *ret  = (TQNodeLock *)[super node];
    ret->_condition  = [aCond retain];
    ret->_statements = [OFMutableArray new];
    return ret;
}
- (void)dealloc
{
    [_condition release];
    [_statements release];
    [super dealloc];
}

- (BOOL)isEqual:(id)b
{
    if(![b isMemberOfClass:[self class]])
        return NO;
    return [_condition isEqual:[(TQNodeLock *)b condition]] && [_statements isEqual:[b statements]];
}

- (id)referencesNode:(TQNode *)aNode
{
    if([aNode isEqual:self])
        return self;
    TQNode *ref = [_condition referencesNode:aNode];
    if(ref)
        return ref;
    return [_statements tq_referencesNode:aNode];
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    aBlock(_condition);
    for(TQNode *stmt in _statements) {
        aBlock(stmt);
    }
}

- (OFString *)description
{
    return [OFString stringWithFormat:@"<lock: %@>", _condition];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(TQError **)aoErr
{
    Module *mod = aProgram.llModule;

    Value *condVal = [_condition generateCodeInProgram:aProgram
                                                 block:aBlock
                                                  root:aRoot
                                                 error:aoErr];
    Value *enterCond = aBlock.builder->CreateCall(aProgram.objc_sync_enter, condVal);
    [self _attachDebugInformationToInstruction:enterCond inProgram:aProgram block:aBlock root:aRoot];

    TQNode *exitNode = [TQNodeCustom nodeWithBlock:^(TQProgram *p, TQNodeBlock *b, TQNodeRootBlock *r) {
        aBlock.builder->CreateCall(aProgram.objc_sync_exit, condVal);
        aBlock.builder->CreateCall(aProgram.TQPopNonLocalReturnStack);
        return (Value *)NULL;
    }];
    // Let the block know it needs to release the lock before returning
    [aBlock.cleanupStatements insertObject:exitNode atIndex:0];
    // If we're inside a loop, the loop needs to know to release the lock before skipping or breaking
    TQNodeWhileBlock *loop = objc_getAssociatedObject(aBlock, TQCurrLoopKey);
    [loop.cleanupStatements insertObject:exitNode atIndex:0];

    // We also need to add a non-local return propagation point where we release the lock
    BasicBlock *lockReleaseBlock = BasicBlock::Create(mod->getContext(), "releaseLockAndPropagate", aBlock.function, 0);
    IRBuilder<> lockReleaseBuilder(lockReleaseBlock);
    BasicBlock *lockBodyBlock = BasicBlock::Create(mod->getContext(), "lockBody", aBlock.function, 0);
    Value *jmpBuf  = aBlock.builder->CreateCall(aProgram.TQPushNonLocalReturnStack, [aBlock.literalPtr generateCodeInProgram:aProgram
                                                                                                                       block:aBlock
                                                                                                                        root:aRoot
                                                                                                                       error:aoErr]);
    Value *jmpRes  = aBlock.builder->CreateCall(aProgram.setjmp, jmpBuf);
    Value *jmpTest = aBlock.builder->CreateICmpEQ(jmpRes, ConstantInt::get(aProgram.llIntTy, 0));
    aBlock.builder->CreateCondBr(jmpTest, lockBodyBlock, lockReleaseBlock);

    lockReleaseBuilder.CreateCall(aProgram.objc_sync_exit, condVal);
    Value *propBuf = lockReleaseBuilder.CreateCall(aProgram.TQPopNonLocalReturnStackAndGetPropagationJumpTarget);
    lockReleaseBuilder.CreateCall2(aProgram.longjmp, propBuf, ConstantInt::get(aProgram.llIntTy, 0));
    lockReleaseBuilder.CreateRet(ConstantPointerNull::get(aProgram.llInt8PtrTy));

    aBlock.basicBlock = lockBodyBlock;
    delete aBlock.builder;
    aBlock.builder = new IRBuilder<>(lockBodyBlock);

    for(TQNode *stmt in _statements) {
        [stmt generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        if([stmt isKindOfClass:[TQNodeReturn class]])
            break;
    }

    if(!aBlock.basicBlock->getTerminator())
        [exitNode generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    // Cleanup done already
    [aBlock.cleanupStatements removeObjectIdenticalTo:exitNode];
    [loop.cleanupStatements removeObjectIdenticalTo:exitNode];

    return NULL;
}
@end

