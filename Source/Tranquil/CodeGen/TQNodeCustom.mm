#import "TQNodeCustom.h"
#import "TQProgram.h"

using namespace llvm;

@implementation TQNodeCustom
@synthesize block=_block;

+ (TQNodeCustom *)nodeWithBlock:(TQNodeCustomBlock)aBlock
{
    TQNodeCustom *ret = [self new];
    ret.block = [aBlock copy];
    return [ret autorelease];
}

+ (TQNodeCustom *)nodeReturningValue:(llvm::Value *)aVal
{
    return [self nodeWithBlock:^(TQProgram *, TQNodeBlock *, TQNodeRootBlock *) {
        return aVal;
    }];
}

- (void)dealloc
{
    [_block release];
    [super dealloc];
}

- (OFString *)description
{
    return [OFString stringWithFormat:@"<custom>"];
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    return [aNode isEqual:self] ? self : nil;
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
                                 error:(TQError **)aoErr
{
    return _block(aProgram, aBlock, aRoot);
}
@end
