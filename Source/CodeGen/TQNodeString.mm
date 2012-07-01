#import "TQNodeString.h"
#import "TQProgram.h"

using namespace llvm;

static Value *_StringWithUTF8StringSel, *_NSStringClassNameConst;

@implementation TQNodeString
@synthesize value=_value;

+ (TQNodeString *)nodeWithCString:(const char *)aStr
{
	return [[[self alloc] initWithCString:aStr] autorelease];
}

- (id)initWithCString:(const char *)aStr
{
	if(!(self = [super init]))
		return nil;

	_value = [[NSString alloc] initWithUTF8String:aStr];

	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<str@ \"%@\">", _value];
}

- (void)dealloc
{
	[_value release];
	[super dealloc];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoError
{
	llvm::IRBuilder<> *builder = aBlock.builder;

	// Returns [NSMutableString stringWithUTF8String:_value]
	if(!_NSStringClassNameConst)
		_NSStringClassNameConst = builder->CreateGlobalStringPtr("NSMutableString", "className_NSMutableString");
	if(!_StringWithUTF8StringSel)
		_StringWithUTF8StringSel = builder->CreateGlobalStringPtr("stringWithUTF8String:", "sel_stringWithUTF8String");

	CallInst *classLookup = builder->CreateCall(aProgram.objc_getClass, _NSStringClassNameConst);
	CallInst *selReg = builder->CreateCall(aProgram.sel_registerName, _StringWithUTF8StringSel);
	Value *strValue = builder->CreateGlobalStringPtr([_value UTF8String]);

	return builder->CreateCall3(aProgram.objc_msgSend, classLookup, selReg, strValue);
}
@end
