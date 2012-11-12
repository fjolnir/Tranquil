#import "TQNodeNothing.h"
#import "TQProgram.h"
#import "TQNodeBlock.h"

using namespace llvm;

@implementation TQNodeNothing

+ (TQNodeNothing *)node
{
    return (TQNodeNothing *)[super node];
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
    return [OFString stringWithFormat:@"<nothing>"];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(TQError **)aoErr
{
    return aBlock.builder->CreateLoad(aProgram.llModule->getOrInsertGlobal("TQNothing", aProgram.llInt8PtrTy));
}
@end
