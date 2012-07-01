#import "TQNodeMethod.h"
#import "TQNodeMessage.h"
#import "TQNodeArgument.h"

using namespace llvm;

@implementation TQNodeMethod
@synthesize type=_type;

+ (TQNodeMethod *)node { return (TQNodeMethod *)[super node]; }

+ (TQNodeMethod *)nodeWithType:(TQMethodType)aType
{
	return [[[self alloc] initWithType:aType] autorelease];
}

- (id)initWithType:(TQMethodType)aType
{
	if(!(self = [super init]))
		return nil;

	_type = aType;

	return self;
}

- (BOOL)addArgument:(TQNodeArgument *)aArgument error:(NSError **)aoError
{
	if(self.arguments.count == 0)
		TQAssertSoft(aArgument.identifier != nil,
		             kTQSyntaxErrorDomain, kTQUnexpectedIdentifier, NO,
		             @"No name given for method");
	[self.arguments addObject:aArgument];

	return YES;
}

- (void)dealloc
{
	[super dealloc];
}

- (NSString *)description
{
	NSMutableString *out = [NSMutableString stringWithString:@"<meth@ "];
	switch(_type) {
		case kTQClassMethod:
			[out appendString:@"+ "];
			break;
		case kTQInstanceMethod:
		default:
			[out appendString:@"- "];
	}
	for(TQNodeArgument *arg in self.arguments) {
		[out appendFormat:@"%@ ", arg];
	}
	[out appendString:@"{"];
	if(self.statements.count > 0) {
		[out appendString:@"\n"];
		for(TQNode *stmt in self.statements) {
			[out appendFormat:@"\t%@\n", stmt];
		}
	}
	[out appendString:@"}>"];
	return out;
}

@end
