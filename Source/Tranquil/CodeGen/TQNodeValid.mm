#import "TQNodeValid.h"
#import "TQNodeBlock.h"
#import "TQProgram.h"

using namespace llvm;

@implementation TQNodeValid
- (NSString *)description
{
    return [NSString stringWithFormat:@"<valid>"];
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
                                 error:(NSError **)aoErr
{
    Module *mod = aProgram.llModule;
    llvm::IRBuilder<> *builder = aBlock.builder;
    return builder->CreateLoad(mod->getOrInsertGlobal("TQValid", aProgram.llInt8PtrTy));
}
@end
