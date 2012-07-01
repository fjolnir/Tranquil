#import "TQNodeReturn.h"
#import "TQProgram.h"
#import "TQNodeVariable.h"
#import "TQNodeBlock.h"

using namespace llvm;

@implementation TQNodeReturn
@synthesize value=_value;
+ (TQNodeReturn *)nodeWithValue:(TQNode *)aValue
{
	return [[[self alloc] initWithValue:aValue] autorelease];
}

- (id)initWithValue:(TQNode *)aValue
{
	if(!(self = [super init]))
		return nil;

	_value = [aValue retain];

	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<ret@ %@>", _value];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoError
{
	IRBuilder<> *builder = aBlock.builder;
	Value *retVal = [_value generateCodeInProgram:aProgram block:aBlock error:aoError];
	// If the return value is a block we must move it to the heap before returning
	if([_value isKindOfClass:[TQNodeBlock class]]) {
		retVal = builder->CreateCall(aProgram._Block_copy, retVal);
	}
	return builder->CreateRet(retVal);
}
@end
