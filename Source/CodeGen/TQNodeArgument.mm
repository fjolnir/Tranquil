#import "TQNodeArgument.h"

using namespace llvm;

@implementation TQNodeArgument
@synthesize identifier=_identifier, passedNode=_passedNode;

+ (TQNodeArgument *)nodeWithPassedNode:(TQNode *)aNode identifier:(NSString *)aIdentifier
{
	return [[[self alloc] initWithPassedNode:aNode identifier:aIdentifier] autorelease];
}

- (id)initWithPassedNode:(TQNode *)aNode identifier:(NSString *)aIdentifier
{
	if(!(self = [super init]))
		return nil;

	_passedNode = [aNode retain];
	_identifier = [aIdentifier retain];

	return self;
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
	TQNode *ref = nil;
	if([aNode isEqual:self])
		ref = self;
	else if((ref = [_passedNode referencesNode:aNode]))
		return ref;
	return ref;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<arg@ %@: %@>", _identifier, _passedNode];
}

- (void)dealloc
{
	[_identifier release];
	[_passedNode release];
	[super dealloc];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoError
{
	return [_passedNode generateCodeInProgram:aProgram block:aBlock error:aoError];
}
@end
