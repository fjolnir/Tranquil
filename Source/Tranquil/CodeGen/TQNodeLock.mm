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
    ret->_statements = [NSMutableArray new];
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

- (NSString *)description
{
    return [NSString stringWithFormat:@"<lock: %@>", _condition];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    Value *condVal = [_condition generateCodeInProgram:aProgram
                                                 block:aBlock
                                                  root:aRoot
                                                 error:aoErr];
    Value *enterCond = aBlock.builder->CreateCall(aProgram.objc_sync_enter, condVal);
    [self _attachDebugInformationToInstruction:enterCond inProgram:aProgram root:aRoot];

    TQNode *exitNode = [TQNodeCustom nodeWithBlock:^(TQProgram *p, TQNodeBlock *b, TQNodeRootBlock *r) {
        aBlock.builder->CreateCall(aProgram.objc_sync_exit, condVal);
        return (Value *)NULL;
    }];
    // Let the block know it needs to release the lock before returning
    [aBlock.cleanupStatements insertObject:exitNode atIndex:0];
    // If we're inside a loop, the loop needs to know to release the lock before skipping or breaking
    TQNodeWhileBlock *loop = objc_getAssociatedObject(aBlock, TQCurrLoopKey);
    [loop.cleanupStatements insertObject:exitNode atIndex:0];

    for(TQNode *stmt in _statements) {
        [stmt generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    }

    [exitNode generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    // Cleanup done already
    [aBlock.cleanupStatements removeObjectIdenticalTo:exitNode];
    [loop.cleanupStatements removeObjectIdenticalTo:exitNode];

    return NULL;
}
@end

