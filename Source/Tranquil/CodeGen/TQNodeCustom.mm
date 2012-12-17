#import "TQNodeCustom.h"
#import "TQProgram.h"

using namespace llvm;

@implementation TQNodeCustom
@synthesize block=_block, references=_references;

+ (TQNodeCustom *)nodeWithBlock:(TQNodeCustomBlock)aBlock
{
    TQNodeCustom *ret = [self new];
    ret.block = [aBlock copy];
    return [ret autorelease];
}

+ (TQNodeCustom *)nodeReturningValue:(llvm::Value *)aVal
{
    return [self nodeWithBlock:^(TQProgram *, TQNodeBlock *, TQNodeRootBlock *, NSError **) {
        return aVal;
    }];
}

- (void)dealloc
{
    [_block release];
    [_references release];
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<custom>"];
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    if([aNode isEqual:self])
        return self;
    return [_references tq_referencesNode:aNode];
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    // Nothing to iterate
}

- (BOOL)replaceChildNodesIdenticalTo:(TQNode *)aNodeToReplace with:(TQNode *)aNodeToInsert
{
    return NO;
}


- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    return _block(aProgram, aBlock, aRoot, aoErr);
}
@end
