#import "TQNodeConstant.h"
#import "TQProgram.h"


using namespace llvm;

@implementation TQNodeConstant

+ (TQNodeConstant *)nodeWithString:(NSString *)aStr{ return (TQNodeConstant *)[super nodeWithString:aStr]; }

- (NSString *)description
{
	return [NSString stringWithFormat:@"<const@ %@>", [self value]];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
	llvm::IRBuilder<> *builder = aBlock.builder;
	Value *className = builder->CreateGlobalStringPtr([self.value UTF8String]);
	return builder->CreateCall(aProgram.objc_getClass, className);
}
@end
