#import "TQNodeBinaryOperator.h"
#import "TQNodeVariable.h"
#import "TQNodeMemberAccess.h"
#import "TQProgram.h"

using namespace llvm;

@implementation TQNodeBinaryOperator
@synthesize type=_type, left=_left, right=_right;

+ (TQNodeBinaryOperator *)nodeWithType:(TQOperatorType)aType left:(TQNode *)aLeft right:(TQNode *)aRight
{
	return [[[self alloc] initWithType:aType left:aLeft right:aRight] autorelease];
}

- (id)initWithType:(TQOperatorType)aType left:(TQNode *)aLeft right:(TQNode *)aRight
{
	if(!(self = [super init]))
		return nil;

	_type = aType;
	_left = [aLeft retain];
	_right = [aRight retain];

	return self;
}

- (void)dealloc
{
	[_left release];
	[_right release];
	[super dealloc];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoError
{
	BOOL isVar = [_left isMemberOfClass:[TQNodeVariable class]];
	BOOL isProperty = [_left isMemberOfClass:[TQNodeMemberAccess class]];
	TQAssertSoft(isVar || isProperty, kTQSyntaxErrorDomain, kTQInvalidAssignee, NO, @"Only variables and object properties can be assigned to");

	NSLog(@"> Assigning to %@", _left);
	Value *right = [_right generateCodeInProgram:aProgram block:aBlock error:aoError];
	[(TQNodeVariable *)_left store:right inProgram:aProgram block:aBlock error:aoError];

	return [_left generateCodeInProgram:aProgram block:aBlock error:aoError];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<op@ %@ %c %@>", _left, _type, _right];
}
@end
