#import "TQNodeValid.h"
#import "TQNodeBlock.h"
#import "TQProgram.h"

using namespace llvm;

@implementation TQNodeValid
- (OFString *)description
{
    return [OFString stringWithFormat:@"<valid>"];
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    return nil;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    // Nothing to iterate
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(TQError **)aoErr
{
    return aBlock.builder->CreateLoad(aProgram.llModule->getOrInsertGlobal("TQValid", aProgram.llInt8PtrTy));
}
@end
