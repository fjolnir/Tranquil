#import "TQNodeClass.h"
#import "TQNodeMethod.h"
#import "TQProgram.h"

using namespace llvm;

@implementation TQNodeClass
@synthesize name=_name, superClassName=_superClassName, classMethods=_classMethods, instanceMethods=_instanceMethods,
	classPtr=_classPtr;

+ (TQNodeClass *)nodeWithName:(NSString *)aName
{
	return [[[self alloc] initWithName:aName] autorelease];
}

- (id)initWithName:(NSString *)aName
{
	if(!(self = [super init]))
		return nil;

	_name = [aName retain];

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
	// -- Method definitions
	IRBuilder<> *builder = aBlock.builder;

	Value *extraBytes = ConstantInt::get( aProgram.llInt64Ty, 0);
	Value *name = builder->CreateGlobalStringPtr([_name UTF8String]);
	// Find the superclass
	NSString *superClassName = _superClassName ? _superClassName : @"NSObject";
	Value *superClassPtr = builder->CreateCall(aProgram.objc_getClass, builder->CreateGlobalStringPtr([superClassName UTF8String]));
	// Allocate the class
	_classPtr = builder->CreateCall3(aProgram.objc_allocateClassPair, superClassPtr, name, extraBytes, [_name UTF8String]);
	
	// Add the methods for the class
	for(TQNodeMethod *method in [_classMethods arrayByAddingObjectsFromArray:_instanceMethods]) {
		[method generateCodeInProgram:aProgram block:aBlock class:self error:aoErr];
		if(*aoErr) return NULL;
	}
	// Register the class
	_classPtr = builder->CreateCall(aProgram.objc_registerClassPair, _classPtr);

	return _classPtr;
}

@end
