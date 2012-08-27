#import "TQNode.h"
#import "../Shared/TQDebug.h"

using namespace llvm;

@implementation TQNode
+ (TQNode *)node
{
    return [[self new] autorelease];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    TQLog(@"Code generation has not been implemented for %@.", [self class]);
    return NULL;
}

- (llvm::Value *)store:(llvm::Value *)aValue
             inProgram:(TQProgram *)aProgram
                 block:(TQNodeBlock *)aBlock
                  root:(TQNodeRootBlock *)aRoot
                 error:(NSError **)aoErr
{
    TQLog(@"Store has not been implemented for %@.", [self class]);
    return NULL;
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    TQLog(@"Node reference check has not been implemented for %@.", [self class]);
    return nil;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    TQLog(@"Node iteration has not been implemented for %@.", [self class]);
}

- (BOOL)insertChildNode:(TQNode *)aNodeToInsert before:(TQNode *)aNodeToShift
{
    TQLog(@"%@ does not support child node insertion.", [self class]);
    return NO;
}

- (BOOL)insertChildNode:(TQNode *)aNodeToInsert after:(TQNode *)aNodeToShift
{
    TQLog(@"%@ does not support child node insertion.", [self class]);
    return NO;
}

- (BOOL)replaceChildNodesIdenticalTo:(TQNode *)aNodeToReplace with:(TQNode *)aNodeToInsert
{
    TQLog(@"%@ does not support child node replacement.", [self class]);
    return NO;
}
@end

@implementation NSArray (TQReferencesNode)
- (TQNode *)tq_referencesNode:(TQNode *)aNode
{
    TQNode *ref;
    for(TQNode *n in self) {
        ref = [n referencesNode:aNode];
        if(ref)
            return ref;
    }
    return nil;
}
@end
