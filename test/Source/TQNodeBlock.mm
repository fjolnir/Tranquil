#import "TQNodeBlock.h"
#import <TQNodeArgument.h>
#import <TQProgram.h>

// Block invoke functions are numbered from 0
#define BLOCK_FUN_PREFIX @"__tq_block_invoke_"

using namespace llvm;

@implementation TQNodeBlock
@synthesize arguments=_arguments, statements=_statements, locals=_locals, name=_name, basicBlock=_basicBlock, function=_function;

+ (TQNodeBlock *)node { return (TQNodeBlock *)[super node]; }

- (id)init
{
	if(!(self = [super init]))
		return nil;

	_arguments = [[NSMutableArray alloc] init];
	_statements = [[NSMutableArray alloc] init];
	_function = NULL;
	_basicBlock = NULL;

	return self;
}

- (NSString *)description
{
	NSMutableString *out = [NSMutableString stringWithString:@"<blk@ {"];
	if(_arguments.count > 0) {
		for(TQNodeArgument *arg in _arguments) {
			[out appendFormat:@"%@ ", arg];
		}
		[out appendString:@"|"];
	}
	if(_statements.count > 0) {
		[out appendString:@"\n"];
		for(TQNode *stmt in _statements) {
			[out appendFormat:@"\t%@\n", stmt];
		}
	}
	[out appendString:@"}>"];
	return out;
}

- (void)dealloc
{
	if(_locals)
		CFRelease(_locals), _locals = NULL;
	[_arguments release];
	[_statements release];
	delete _basicBlock;
	delete _function;
	[super dealloc];
}

- (BOOL)addArgument:(TQNodeArgument *)aArgument error:(NSError **)aoError
{
	if(_arguments.count == 0)
		TQAssertSoft(aArgument.identifier == nil,
		             kTQSyntaxErrorDomain, kTQUnexpectedIdentifier, NO,
		             @"First argument of a block can not have an identifier");
	[_arguments addObject:aArgument];

	return YES;
}



- (BOOL)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
	TQAssert(!_basicBlock && !_function, @"Tried to regenerate code for block %@", _name);
	llvm::Module *mod = aProgram.llModule;
	llvm::PointerType *int8PtrTy = aProgram.llInt8PtrTy;

	// Build the invoke function
	std::vector<Type *> paramTypes(_arguments.count, int8PtrTy);
	FunctionType* funType = FunctionType::get(
		/*Result=*/int8PtrTy,
		/*Params=*/paramTypes,
		/*isVarArg=*/false); // TODO: Support variadics

	const char *funName = [_name UTF8String];
	
	_function = mod->getFunction(funName);
	if (!_function) {
		_function = Function::Create(
			/*Type=*/    funType,
			/*Linkage=*/ GlobalValue::ExternalLinkage,
			/*Name=*/    funName, mod); 
		_function->setCallingConv(CallingConv::C);
	}

	_basicBlock = BasicBlock::Create(mod->getContext(), "", _function, 0);

	NSError *err = nil;
	for(TQNode *node in _statements) {
		[node generateCodeInProgram:aProgram block:self error:&err];
		if(err) {
			NSLog(@"Error: %@", err);
			//return NO;
		}
	}

	// Return (TODO: Actually support returning values)
	ReturnInst::Create(mod->getContext(), ConstantPointerNull::get(int8PtrTy), _basicBlock);

	return YES;
}
@end
