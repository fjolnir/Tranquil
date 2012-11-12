#import "TQNodeNil.h"
#import "TQProgram.h"

using namespace llvm;

@implementation TQNodeNil

+ (TQNodeNil *)node
{
    return (TQNodeNil *)[super node];
}

- (id)referencesNode:(TQNode *)aNode
{
    return nil;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    // Nothing to iterate
}

- (OFString *)description
{
    return [OFString stringWithFormat:@"<nil>"];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(TQError **)aoErr
{
    return ConstantPointerNull::get(aProgram.llInt8PtrTy);
}
@end
