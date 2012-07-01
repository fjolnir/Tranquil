#import "TQNodeReturn.h"
#import "TQProgram.h"
#import "TQNodeVariable.h"

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
	Value *retVal = [_value generateCodeInProgram:aProgram block:aBlock error:aoError];
	return ReturnInst::Create(aProgram.llModule->getContext(), retVal, aBlock.basicBlock);
}
@end
