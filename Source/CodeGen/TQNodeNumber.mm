#import "TQNodeNumber.h"
#import "TQProgram.h"

using namespace llvm;

@implementation TQNodeNumber
@synthesize value=_value;

+ (TQNodeNumber *)nodeWithDouble:(double)aDouble
{
	return [[[self alloc] initWithDouble:aDouble] autorelease];
}

- (id)initWithDouble:(double)aDouble
{
	if(!(self = [super init]))
		return nil;

	_value = [[NSNumber alloc] initWithDouble:aDouble];

	return self;
}

- (void)dealloc
{
	[_value release];
	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<num@ %f>", _value.doubleValue];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoError
{
	Module *mod = aProgram.llModule;
	llvm::IRBuilder<> *builder = aBlock.builder;

	// Returns [NSNumber numberWithDouble:_value]
	Value *selector = builder->CreateLoad(mod->getOrInsertGlobal("TQNumberWithDoubleSel", aProgram.llInt8PtrTy));
	Value *klass    = mod->getOrInsertGlobal("OBJC_CLASS_$_TQNumber", aProgram.llInt8Ty);

	ConstantFP *doubleValue = ConstantFP::get(aProgram.llModule->getContext(), APFloat([_value doubleValue]));

	return builder->CreateCall3(aProgram.objc_msgSend, klass, selector, doubleValue);
}
@end
