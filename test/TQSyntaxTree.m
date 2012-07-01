#include "TQSyntaxTree.h"

NSString * const kTQSyntaxErrorDomain = @"org.tranquil.syntax";

@implementation TQSyntaxNode
- (BOOL)generateCode:(NSError **)aoErr
{
	return YES;
}
@end

@implementation TQSyntaxNodeVariable
@synthesize name=_name;

- (id)initWithName:(NSString *)aName
{
	if(!(self = [super init]))
		return nil;

	_name = [aName retain];

	return self;
}

- (void)dealloc
{
	[_name release];
	[super dealloc];
}
@end

@implementation TQSyntaxNodeString
@synthesize value=_value;

- (id)initWithCString:(const char *)aStr
{
	if(!(self = [super init]))
		return nil;

	_value = [[NSString alloc] initWithUTF8String:aStr];

	return self;
}

- (void)dealloc
{
	[_value release];
	[super dealloc];
}
@end

@implementation TQSyntaxNodeIdentifier
@end

@implementation TQSyntaxNodeNumber
@synthesize value=_value;

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
@end


@implementation TQSyntaxNodeArgument
@synthesize identifier=_identifier, name=_name;

- (id)initWithName:(NSString *)aName identifier:(NSString *)aIdentifier
{
	if(!(self = [super init]))
		return nil;

	_name = [aName retain];
	_identifier = [aIdentifier retain];

	return self;
}

- (void)dealloc
{
	[_identifier release];
	[_name release];
	[super dealloc];
}
@end


@implementation TQSyntaxNodeBlock
@synthesize arguments=_arguments, statements=_statements;

- (id)init
{
	if(!(self = [super init]))
		return nil;

	_arguments = [[NSMutableArray alloc] init];
	_statements = [[NSMutableArray alloc] init];

	return self;
}

- (void)dealloc
{
	[_arguments release];
	[_statements release];
	[super dealloc];
}

- (BOOL)addArgument:(TQSyntaxNodeArgument *)aArgument error:(NSError **)aoError
{
	if(_arguments.count == 0)
		TQAssertSoft(aArgument.identifier == nil,
		             kTQSyntaxErrorDomain, kTQUnexpectedIdentifier,
		             @"First argument of a block can not have an identifier");
	[_arguments addObject:aArgument];

	return YES;
}
@end


@implementation TQSyntaxNodeCall
@synthesize callee=_callee, arguments=_arguments;

- (id)initWithCallee:(TQSyntaxNode *)aCallee
{
	if(!(self = [super init]))
		return nil;

	_callee = [aCallee retain];
	_arguments = [[NSMutableArray alloc] init];

	return self;
}

- (void)dealloc
{
	[_callee release];
	[_arguments release];
	[super dealloc];
}
@end

@implementation TQSyntaxNodeClass
@synthesize name=_name, superClassName=_superClassName, classMethods=_classMethods, instanceMethods=_instanceMethods;

- (id)initWithName:(NSString *)aName superClass:(NSString *)aSuperClass
{
	if(!(self = [super init]))
		return nil;

	_name = [aName retain];
	_superClassName = [aSuperClass retain];

	_classMethods = [[NSMutableArray alloc] init];
	_instanceMethods = [[NSMutableArray alloc] init];

	return self;
}

- (void)dealloc
{
	[_name release];
	[_superClassName release];
	[_classMethods release];
	[_instanceMethods release];
	[super dealloc];
}
@end

@implementation TQSyntaxNodeMethod
@synthesize type=_type;

- (id)initWithType:(TQMethodType)aType
{
	if(!(self = [super init]))
		return nil;

	_type = aType;

	return self;
}

- (void)dealloc
{
	[super dealloc];
}
@end


@implementation TQSyntaxNodeMessage
@synthesize receiver=_receiver, arguments=_arguments;

- (id)initWithReceiver:(TQSyntaxNode *)aNode
{
	if(!(self = [super init]))
		return nil;
	
	_receiver = [aNode retain];
	_arguments = [[NSMutableArray alloc] init];

	return self;
}

- (void)dealloc
{
	[_receiver release];
	[_arguments release];
	[super dealloc];
}
@end

@implementation TQSyntaxNodeMemberAccess
@synthesize receiver=_receiver, property=_property;

- (id)initWithReceiver:(TQSyntaxNode *)aReceiver property:(NSString *)aProperty
{
	if(!(self = [super init]))
		return nil;

	_receiver = [aReceiver retain];
	_property = [aProperty retain];

	return self;
}

- (void)dealloc
{
	[_receiver release];
	[_property release];
	[super dealloc];
}
@end

@implementation TQSyntaxNodeBinaryOperator
@synthesize type=_type, left=_left, right=_right;

- (id)initWithType:(TQOperatorType)aType left:(TQSyntaxNode *)aLeft right:(TQSyntaxNode *)aRight
{
	if(!(self = [super init]))
		return nil;

	_type = aType;
	_left = [aLeft retain];
	_right = [aLeft retain];

	return self;
}

- (void)dealloc
{
	[_left release];
	[_right release];
	[super dealloc];
}
@end


@implementation TQSyntaxTree
@end
