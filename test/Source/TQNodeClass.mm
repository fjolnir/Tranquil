#import "TQNodeClass.h"
#import "TQNodeMethod.h"

using namespace llvm;

@implementation TQNodeClass
@synthesize name=_name, superClassName=_superClassName, classMethods=_classMethods, instanceMethods=_instanceMethods;

+ (TQNodeClass *)nodeWithName:(NSString *)aName superClass:(NSString *)aSuperClass error:(NSError **)aoError
{
	return [[[self alloc] initWithName:aName superClass:aSuperClass error:aoError] autorelease];
}

- (id)initWithName:(NSString *)aName superClass:(NSString *)aSuperClass error:(NSError **)aoError
{
	NSString *first = [aName substringToIndex:1];
	TQAssertSoft([first isEqualToString:[first capitalizedString]],
	             kTQSyntaxErrorDomain, kTQInvalidClassName, nil,
	             @"Classes must be capitalized, %@ was not.", aName);
	if(aSuperClass) {
		first = [aSuperClass substringToIndex:1];
		TQAssertSoft([first isEqualToString:[first capitalizedString]],
		             kTQSyntaxErrorDomain, kTQInvalidClassName, nil,
		             @"Classes must be capitalized, %@ was not.", aName);
	}

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

- (NSString *)description
{
	NSMutableString *out = [NSMutableString stringWithFormat:@"<cls@ class %@", _name];
	if(_superClassName)
		[out appendFormat:@" < %@", _superClassName];
	[out appendString:@"\n"];

	for(TQNodeMethod *meth in _classMethods) {
		[out appendFormat:@"%@\n", meth];
	}
	if(_classMethods.count > 0 && _instanceMethods.count > 0)
		[out appendString:@"\n"];
	for(TQNodeMethod *meth in _instanceMethods) {
		[out appendFormat:@"%@\n", meth];
	}

	[out appendString:@"end>"];
	return out;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
	// -- Type definitions
	// -- Function definitions
	
	return NULL;
}

@end
