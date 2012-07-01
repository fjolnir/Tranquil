#import "TQNodeNil.h"
#import "TQProgram.h"

using namespace llvm;

@implementation TQNodeNil

+ (TQNodeNil *)node
{
	return (TQNodeNil *)[super node];
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<nil>"];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                 error:(NSError **)aoError
{
	return ConstantPointerNull::get(aProgram.llInt8PtrTy);
}
@end
