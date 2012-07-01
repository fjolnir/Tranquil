#import "TQNodeArgumentDef.h"

using namespace llvm;

@implementation TQNodeArgumentDef
@synthesize identifier=_identifier, localName=_localName;

+ (TQNodeArgumentDef *)nodeWithLocalName:(NSString *)aName identifier:(NSString *)aIdentifier
{
	return [[[self alloc] initWithLocalName:aName identifier:aIdentifier] autorelease];
}

- (id)initWithLocalName:(NSString *)aName identifier:(NSString *)aIdentifier
{
	if(!(self = [super init]))
		return nil;

	_localName = [aName retain];
	_identifier = [aIdentifier retain];

	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<argdef@ %@: %@>", _identifier, _localName];
}

- (void)dealloc
{
	[_identifier release];
	[_localName release];
	[super dealloc];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoError
{
	TQAssert(NO, "Argument definitions do not generate code");
	return NULL;
}
@end
