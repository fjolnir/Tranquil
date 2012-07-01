#import "TQNodeNumber.h"

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
}
@end
