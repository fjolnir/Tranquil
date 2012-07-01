#import "TQNodeMethod.h"
#import "TQNodeMessage.h"
#import "TQNodeArgument.h"
#import "TQNodeClass.h"
#import "TQProgram.h"
#import "TQNodeArgumentDef.h"

using namespace llvm;

@implementation TQNodeMethod
@synthesize type=_type;

+ (TQNodeMethod *)node { return [[[self alloc] init] autorelease]; }

+ (TQNodeMethod *)nodeWithType:(TQMethodType)aType
{
	return [[[self alloc] initWithType:aType] autorelease];
}

- (id)initWithType:(TQMethodType)aType
{
	if(!(self = [super init]))
		return nil;

	_type = aType;

	// Methods must take a self argument
	[self addArgument:[TQNodeArgumentDef nodeWithLocalName:@"self" identifier:nil] error:nil];

	return self;
}

- (id)init
{
	return [self initWithType:kTQInstanceMethod];
}

- (BOOL)addArgument:(TQNodeArgument *)aArgument error:(NSError **)aoError
{
	if(self.arguments.count == 2)
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


- (NSString *)_selectorString
{
	NSMutableString *selector = [NSMutableString string];
	for(TQNodeArgumentDef *arg in self.arguments) {
		if([arg.localName isEqualToString:@"self"] || [arg.localName isEqualToString:@"__blk"])
			continue;
		if(arg.identifier)
			[selector appendString:arg.identifier];
		if(arg.localName)
			[selector appendString:@":"];
	}
	return selector;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoError
{
	TQAssertSoft(NO, kTQGenericErrorDomain, kTQGenericError, NULL, @"Methods require their class to be passed to generate code.");
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                 class:(TQNodeClass *)aClass
                                 error:(NSError **)aoErr
{
	Value *block = [super generateCodeInProgram:aProgram block:aBlock error:aoErr];
	if(*aoErr)
		return NULL;
	IRBuilder<> *builder = aBlock.builder;

	Value *imp = builder->CreateCall(aProgram.imp_implementationWithBlock, block);
	Value *signature = builder->CreateGlobalStringPtr([[self signature] UTF8String]);
	Value *selector = builder->CreateCall(aProgram.sel_registerName, builder->CreateGlobalStringPtr([[self _selectorString] UTF8String]));

	Value *classPtr = aClass.classPtr;
	if(_type == kTQClassMethod)
		classPtr = builder->CreateCall(aProgram.object_getClass, classPtr);
	Value *oldImp = builder->CreateCall4(aProgram.class_replaceMethod, classPtr, selector, imp, signature);

	return NULL;
}

@end
