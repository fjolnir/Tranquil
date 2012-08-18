#import "TQNodeCustom.h"
#import "../TQProgram.h"

using namespace llvm;

@implementation TQNodeCustom
@synthesize block=_block;

+ (TQNodeCustom *)nodeWithBlock:(TQNodeCustomBlock)aBlock
{
    TQNodeCustom *ret = [self new];
    ret.block = aBlock;
    return [ret autorelease];
}

- (void)dealloc
{
    [_block release];
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<custom>"];
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
                                 error:(NSError **)aoErr
{
    return _block(aProgram, aBlock, aRoot);
}
@end
