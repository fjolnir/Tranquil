#import "TQNodeConstant.h"
#import "TQNodeBlock.h"
#import "ObjcSupport/TQHeaderParser.h"
#import "TQProgram.h"


using namespace llvm;

@implementation TQNodeConstant

+ (TQNodeConstant *)nodeWithString:(NSMutableString *)aStr{ return (TQNodeConstant *)[super nodeWithString:aStr]; }

- (NSString *)description
{
    return [NSString stringWithFormat:@"<const@ %@>", [self value]];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    TQNode *bridgedNode = [aProgram.objcParser entityNamed:self.value];
    if(bridgedNode)
        return [bridgedNode generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    else {
        if(aProgram.useAOTCompilation)
            return aBlock.builder->CreateCall(aProgram.objc_getClass, [aProgram getGlobalStringPtr:self.value inBlock:aBlock]);
        else {
            Class kls = objc_getClass([self.value UTF8String]);
            if(kls)
                return ConstantExpr::getIntToPtr(ConstantInt::get(aProgram.llLongTy, (uintptr_t)kls), aProgram.llInt8PtrTy);
            else
                return aBlock.builder->CreateCall(aProgram.objc_getClass, [aProgram getGlobalStringPtr:self.value inBlock:aBlock]);
        }
    }
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    // Nothing to iterate
}

@end
