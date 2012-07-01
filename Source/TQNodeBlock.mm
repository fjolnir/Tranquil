#import "TQNodeBlock.h"
#import "TQNodeArgumentDef.h"
#import "TQProgram.h"
#import "TQNodeIdentifier.h"
#import "TQNodeVariable.h"
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
	_locals = [[NSMutableDictionary alloc] init];
	_function = NULL;
	_basicBlock = NULL;

	// Block invocations are always passed the block itself as the first argument
	[self addArgument:[TQNodeArgumentDef nodeWithLocalName:@"__blk" identifier:nil] error:nil];

	return self;
}

- (NSString *)description
{
	NSMutableString *out = [NSMutableString stringWithString:@"<blk@ {"];
	if(_arguments.count > 0) {
		for(TQNodeArgumentDef *arg in _arguments) {
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

- (NSString *)signature
{
	return @"%@:%@";
}

- (BOOL)addArgument:(TQNodeArgumentDef *)aArgument error:(NSError **)aoError
{
	if([_arguments count] < 2)
		TQAssertSoft(aArgument.identifier == nil,
		             kTQSyntaxErrorDomain, kTQUnexpectedIdentifier, NO,
		             @"First argument of a block can not have an identifier");
	[_arguments addObject:aArgument];

	return YES;
}
- (llvm::Constant *)generateCBlockDescriptorInProgram:(TQProgram *)aProgram
{
	llvm::Module *mod = aProgram.llModule;
	SmallVector<llvm::Constant*, 6> elements;

	// reserved
	elements.push_back(llvm::ConstantInt::get( aProgram.llInt64Ty, 0));  // TODO: Use 32bit on x86

	// Size
	 elements.push_back(llvm::ConstantInt::get(aProgram.llInt64Ty, 0)); // TODO: Use actual size

	 // TODO: Add Copy helper
	 // TODO: Add Dispose helper

	 // Signature
	 elements.push_back(ConstantExpr::getBitCast((GlobalVariable*)_builder->CreateGlobalString([[self signature]
	 UTF8String]), aProgram.llInt8PtrTy));

	// GC Layout (unused in objc 2)
	elements.push_back(llvm::Constant::getNullValue(aProgram.llInt8PtrTy));

	llvm::Constant *init = llvm::ConstantStruct::getAnon(elements);

	llvm::GlobalVariable *global = new llvm::GlobalVariable(*mod, init->getType(), true,
	                             	llvm::GlobalValue::InternalLinkage,
	                             	init, "__tq_block_descriptor_tmp");

	return llvm::ConstantExpr::getBitCast(global, aProgram.llInt8PtrTy);
	
}
- (llvm::Constant *)generateCBlockInProgram:(TQProgram *)aProgram
{
	llvm::Module *mod = aProgram.llModule;
	// Build the block struct
	int BlockHeaderSize = 5;
	//llvm::Constant *fields[BlockHeaderSize];
	std::vector<Constant *> fields;

	// isa
	Constant *nsc;
	if(mod->getNamedValue("_NSConcreteGlobalBlock"))
		nsc = llvm::ConstantExpr::getBitCast(mod->getNamedValue("_NSConcreteGlobalBlock"), aProgram.llInt8PtrPtrTy);
	else
		nsc = new llvm::GlobalVariable(*mod, aProgram.llInt8PtrTy, false,
                             llvm::GlobalValue::ExternalLinkage,
                             0, "_NSConcreteGlobalBlock", 0,
                             false, 0);
	fields.push_back(nsc);

	// __flags
	int flags = BLOCK_IS_GLOBAL | BLOCK_HAS_SIGNATURE;
	//if (blockInfo.UsesStret) flags |= BLOCK_USE_STRET;

	fields.push_back(ConstantInt::get(aProgram.llIntTy, flags));

	// Reserved
	fields.push_back(Constant::getNullValue(aProgram.llIntTy));

	// Function
	fields.push_back(_function);//ConstantExpr::getBitCast(_function, aProgram.llInt8PtrTy));

	// Descriptor
	fields.push_back([self generateCBlockDescriptorInProgram:aProgram]);

	llvm::Constant *init = ConstantStruct::getAnon(fields);

	GlobalVariable *global = new llvm::GlobalVariable(*mod,
                             init->getType(),
                             /*constant*/ true,
                             llvm::GlobalVariable::InternalLinkage,
                             init,
                             "__tq_block_literal_global");

	return llvm::ConstantExpr::getBitCast(global, aProgram.llInt8PtrTy);
}
- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
	static int blockId = -1; // TODO: implement this in a proper fashion
	++blockId;

	TQAssert(!_basicBlock && !_function, @"Tried to regenerate code for block %@", _name);
	llvm::Module *mod = aProgram.llModule;
	llvm::PointerType *int8PtrTy = aProgram.llInt8PtrTy;

	// Build the invoke function
	std::vector<Type *> paramTypes(_arguments.count, int8PtrTy);
	FunctionType* funType = FunctionType::get(int8PtrTy, paramTypes, false); // TODO: Support variadics

	const char *funName = [[NSString stringWithFormat:@"__tq_block_invoke_%d", blockId] UTF8String];
	
	_function = mod->getFunction(funName);
	if (!_function) {
		_function = Function::Create(funType, GlobalValue::ExternalLinkage, funName, mod);
		_function->setCallingConv(CallingConv::C);
	}

	_basicBlock = BasicBlock::Create(mod->getContext(), "entry", _function, 0);
	_builder = new IRBuilder<>(_basicBlock);

	llvm::Function::arg_iterator argumentIterator = _function->arg_begin();
	for (unsigned i = 0; i < _arguments.count; ++i, ++argumentIterator)
	{
		IRBuilder<> tempBuilder(&_function->getEntryBlock(), _function->getEntryBlock().begin());
		NSString *argVarName = [[_arguments objectAtIndex:i] localName];

		AllocaInst *allocaInst = tempBuilder.CreateAlloca(int8PtrTy, 0, [argVarName UTF8String]);
		_builder->CreateStore(argumentIterator, allocaInst);

		TQNodeVariable *local = [TQNodeVariable nodeWithName:argVarName];
		local.alloca = allocaInst;
		NSLog(@"registering arg local %@: %@ alloca: %p", argVarName, local, allocaInst);
		[_locals setObject:local forKey:argVarName];
	}
	

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

	Constant *literal = [self generateCBlockInProgram:aProgram];

	return literal;
}
@end
