#import "TQNodeCollect.h"
#import "TQNode+Private.h"
#import "TQProgram.h"
#import "TQNodeOperator.h"
#import "TQNodeLoopBlock.h"
#import "TQNodeCustom.h"
#import <objc/runtime.h>

using namespace llvm;

@implementation TQNodeCollect
@synthesize statements=_statements;

+ (TQNodeCollect *)node
{
    return (TQNodeCollect *)[super node];
}
- (void)dealloc
{
    [_statements release];
    [super dealloc];
}

- (BOOL)isEqual:(id)b
{
    if(![b isMemberOfClass:[self class]])
        return NO;
    return [_statements isEqual:[b statements]];
}

- (id)referencesNode:(TQNode *)aNode
{
    if([aNode isEqual:self])
        return self;
    return [_statements tq_referencesNode:aNode];
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    for(TQNode *stmt in _statements) {
        aBlock(stmt);
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<collect>"];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    Value *pool = aBlock.builder->CreateCall(aProgram.objc_autoreleasePoolPush);

    TQNode *exitNode = [TQNodeCustom nodeWithBlock:^(TQProgram *p, TQNodeBlock *b, TQNodeRootBlock *r) {
        aBlock.builder->CreateCall(aProgram.objc_autoreleasePoolPop, pool);
        return (Value *)NULL;
    }];
    // Let the block know it needs to pop before returning
    [aBlock.cleanupStatements insertObject:exitNode atIndex:0];
    // If we're inside a loop, the loop needs to know to pop before skipping or breaking
    TQNodeWhileBlock *loop = objc_getAssociatedObject(aBlock, TQCurrLoopKey);
    [loop.cleanupStatements insertObject:exitNode atIndex:0];

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

