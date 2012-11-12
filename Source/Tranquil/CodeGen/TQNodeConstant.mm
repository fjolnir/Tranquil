#import "TQNodeConstant.h"
#import "TQNodeBlock.h"
#import "ObjcSupport/TQHeaderParser.h"
#import "TQProgram.h"


using namespace llvm;

@implementation TQNodeConstant

+ (TQNodeConstant *)nodeWithString:(OFMutableString *)aStr{ return (TQNodeConstant *)[super nodeWithString:aStr]; }

- (OFString *)description
{
    return [OFString stringWithFormat:@"<const@ %@>", [self value]];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(TQError **)aoErr
{
    TQNode *bridgedNode = [aProgram.objcParser entityNamed:self.value];
    if(bridgedNode)
        return [bridgedNode generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    else
        return aBlock.builder->CreateCall(aProgram.objc_getClass, [aProgram getGlobalStringPtr:self.value inBlock:aBlock]);
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    // Nothing to iterate
}

@end
