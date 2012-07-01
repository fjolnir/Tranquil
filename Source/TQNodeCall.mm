#import "TQNodeCall.h"
#import "TQProgram.h"
#import "TQNodeBlock.h"
#import "TQNodeArgument.h"
#import "TQNodeVariable.h"

using namespace llvm;

@implementation TQNodeCall
@synthesize callee=_callee, arguments=_arguments;

+ (TQNodeCall *)nodeWithCallee:(TQNode *)aCallee
{
return [[[self alloc] initWithCallee:aCallee] autorelease];
}

- (id)initWithCallee:(TQNode *)aCallee
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

- (NSString *)description
{
	NSMutableString *out = [NSMutableString stringWithString:@"<call@ "];
	if(_callee)
		[out appendFormat:@"%@: ", _callee];

	for(TQNodeArgument *arg in _arguments) {
		[out appendFormat:@"%@ ", arg];
	}

	[out appendString:@".>"];
	return out;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
	IRBuilder<> *builder = aBlock.builder;

	// Debug print (TODO: Remove and implement actual function bridging)
	if([_callee isMemberOfClass:[TQNodeVariable class]] && [[_callee name] isEqualToString:@"print"]) {
		NSLog(@"-------------NSLOG");
		std::vector<Type*> nslog_args;
		nslog_args.push_back(aProgram.llInt8PtrTy);
		FunctionType *nslog_type = FunctionType::get(aProgram.llVoidTy, nslog_args, true);

		Function *func_nslog = aProgram.llModule->getFunction("NSLog");
		if(!func_nslog) {
			func_nslog = Function::Create(nslog_type, GlobalValue::ExternalLinkage, "NSLog", aProgram.llModule);
			func_nslog->setCallingConv(CallingConv::C);
		}
		std::vector<Value*> args;
		for(TQNodeArgument *arg in _arguments) {
			args.push_back([arg generateCodeInProgram:aProgram block:aBlock error:aoErr]);
		}
		builder->CreateCall(func_nslog, args);
		return NULL;
	}

	// Extract the invoke function pointer and call it.
	Type *blockPtrTy = PointerType::getUnqual(aProgram.llBlockLiteralType);

	Value *callee = [_callee generateCodeInProgram:aProgram block:aBlock error:aoErr];

	Value *blockLiteral = builder->CreateBitCast(callee, blockPtrTy);

	Value *funPtr = builder->CreateStructGEP(blockLiteral, 3);

	std::vector<Value*> args;
	args.push_back(callee);
	for(TQNodeArgument *arg in _arguments) {
		args.push_back([arg generateCodeInProgram:aProgram block:aBlock error:aoErr]);
	}

	// Load the function and cast it to the correct type
	Value *fun = builder->CreateLoad(funPtr);
	std::vector<Type *> paramTypes(_arguments.count+1,  aProgram.llInt8PtrTy);
	FunctionType *funType = FunctionType::get(aProgram.llInt8PtrTy, paramTypes, false);
	Type *funPtrType = PointerType::getUnqual(funType);

	fun = builder->CreateBitCast(fun, funPtrType);
	return builder->CreateCall(fun, args);
}
@end
