#import "TQNodeBlock.h"
#import <TQNodeArgument.h>
#import <TQProgram.h>

// Block invoke functions are numbered from 0
#define BLOCK_FUN_PREFIX @"__tq_block_invoke_"

using namespace llvm;

enum BlockFlag_t {
  BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
  BLOCK_HAS_CXX_OBJ =       (1 << 26),
  BLOCK_IS_GLOBAL =         (1 << 28),
  BLOCK_USE_STRET =         (1 << 29),
  BLOCK_HAS_SIGNATURE  =    (1 << 30)
};

enum BlockFieldFlag_t {
  BLOCK_FIELD_IS_OBJECT   = 0x03,  /* id, NSObject, __attribute__((NSObject)),
                                    block, ... */
  BLOCK_FIELD_IS_BLOCK    = 0x07,  /* a block variable */

  BLOCK_FIELD_IS_BYREF    = 0x08,  /* the on stack structure holding the __block
                                    variable */
  BLOCK_FIELD_IS_WEAK     = 0x10,  /* declared __weak, only used in byref copy
                                    helpers */
  BLOCK_FIELD_IS_ARC      = 0x40,  /* field has ARC-specific semantics */
  BLOCK_BYREF_CALLER      = 128,   /* called from __block (byref) copy/dispose
                                      support routines */
  BLOCK_BYREF_CURRENT_MAX = 256
};

@implementation TQNodeBlock
@synthesize arguments=_arguments, statements=_statements, locals=_locals, name=_name, basicBlock=_basicBlock, function=_function, builder=_builder;

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
	[_locals release];
	[_arguments release];
	[_statements release];
	delete _basicBlock;
	delete _function;
	delete _builder;
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

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
	TQAssert(!_basicBlock && !_function, @"Tried to regenerate code for block %@", _name);
	llvm::Module *mod = aProgram.llModule;
	llvm::PointerType *int8PtrTy = aProgram.llInt8PtrTy;

	// Build the invoke function
	std::vector<Type *> paramTypes(_arguments.count, int8PtrTy);
	FunctionType* funType = FunctionType::get(int8PtrTy, paramTypes, false); // TODO: Support variadics

	const char *funName = [_name UTF8String];
	
	_function = mod->getFunction(funName);
	if (!_function) {
		_function = Function::Create(funType, GlobalValue::ExternalLinkage, funName, mod);
		_function->setCallingConv(CallingConv::C);
	}

	_basicBlock = BasicBlock::Create(mod->getContext(), "entry", _function, 0);
	_builder = new IRBuilder<>(_basicBlock);
	

	NSError *err = nil;
	Value*foo;
	for(TQNode *node in _statements) {
		foo = [node generateCodeInProgram:aProgram block:self error:&err];
		if(err) {
			NSLog(@"Error: %@", err);
			//return NO;
		}
	}

	// Return (TODO: Actually support returning values)
	if(!_basicBlock->getTerminator())
		ReturnInst::Create(mod->getContext(), ConstantPointerNull::get(int8PtrTy), _basicBlock);

	// Build the block struct
	int BlockHeaderSize = 5;
	//llvm::Constant *fields[BlockHeaderSize];
	std::vector<Constant *> fields;

	// isa
	Constant *nsc;
	if(mod->getNamedValue("_NSConcreteGlobalBlock"))
		llvm::ConstantExpr::getBitCast(mod->getNamedValue("_NSConcreteGlobalBlock"), aProgram.llInt8PtrPtrTy);
	else
		nsc = new llvm::GlobalVariable(*mod, aProgram.llInt8PtrPtrTy, false,
                             llvm::GlobalValue::ExternalLinkage,
                             0, "_NSConcreteGlobalBlock", 0,
                             false, 0);
	printf("---------------------------------------%p\n", nsc);
	//fields[0] = mod->getNamedValue("_NSConcreteGlobalBlock");// CGM.getNSConcreteGlobalBlock();
	fields.push_back(nsc);
	// __flags
	int flags = BLOCK_IS_GLOBAL | BLOCK_HAS_SIGNATURE;
	//if (blockInfo.UsesStret) flags |= BLOCK_USE_STRET;
									  
	fields.push_back(ConstantInt::get(aProgram.llIntTy, flags));

	// Reserved
	fields.push_back(Constant::getNullValue(aProgram.llIntTy));

	// Function
	fields.push_back(_function);

	// Descriptor
	//fields[4] = buildBlockDescriptor(CGM, blockInfo);

	llvm::Constant *init = ConstantStruct::getAnon(fields);

	GlobalVariable *literal =
    new llvm::GlobalVariable(*mod,
                             init->getType(),
                             /*constant*/ true,
                             llvm::GlobalVariable::InternalLinkage,
                             init,
                             "__block_literal_global");


	return _function;
}
@end
