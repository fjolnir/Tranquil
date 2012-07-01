#import "TQNodeBlock.h"
#import "TQNodeArgumentDef.h"
#import "TQProgram.h"
#import "TQNodeIdentifier.h"
#import "TQNodeVariable.h"
// Block invoke functions are numbered from 0
#define TQ_BLOCK_FUN_PREFIX @"__tq_block_invoke_"

using namespace llvm;

@implementation TQNodeBlock
@synthesize arguments=_arguments, statements=_statements, locals=_locals, name=_name,
	basicBlock=_basicBlock, function=_function, builder=_builder;

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
	return @"@:@";
}

- (BOOL)addArgument:(TQNodeArgumentDef *)aArgument error:(NSError **)aoError
{
	if([_arguments count] < 2)
		TQAssertSoft(aArgument.identifier == nil,
		             kTQSyntaxErrorDomain, kTQUnexpectedIdentifier, NO,
		             @"First argument of a block can not have an identifier");
	TQAssertSoft(![_arguments containsObject:aArgument],
	             kTQSyntaxErrorDomain, kTQUnexpectedIdentifier, NO,
	             @"Duplicate arguments for '%@'", aArgument.localName);

	[_arguments addObject:aArgument];

	return YES;
}

- (void)setStatements:(NSArray *)aStatements
{
	NSArray *old = _statements;
	_statements = [aStatements mutableCopy];
	[old release];
}


- (llvm::Type *)_blockDescriptorTypeInProgram:(TQProgram *)aProgram
{
	static Type *descriptorType = NULL;
	if(descriptorType)
		return descriptorType;

	Type *i8PtrTy = aProgram.llInt8PtrTy;
	Type *longTy  = aProgram.llInt64Ty; // Should be unsigned

	descriptorType = StructType::create("struct.__block_descriptor",
	                                    longTy,  // reserved
	                                    longTy,  // size ( = sizeof(literal))
	                                    i8PtrTy, // copy_helper(void *dst, void *src)
	                                    i8PtrTy, // dispose_helper(void *blk)
	                                    NULL);
	descriptorType = PointerType::getUnqual(descriptorType);
	return descriptorType;
}

- (llvm::Type *)_genericBlockLiteralTypeInProgram:(TQProgram *)aProgram
{
	static Type *literalType = NULL;
	if(literalType)
		return literalType;

	Type *i8PtrTy = aProgram.llInt8PtrTy;
	Type *intTy   = aProgram.llIntTy;

	literalType = StructType::create("struct.__block_literal_generic",
	                                 aProgram.llInt8PtrTy, // isa
	                                 intTy,                // flags
	                                 intTy,                // reserved
	                                 i8PtrTy,              // invoke(void *blk, ...)
	                                 [self _blockDescriptorTypeInProgram:aProgram],
	                                 NULL);
	return literalType;
}

- (llvm::Type *)_blockLiteralTypeInProgram:(TQProgram *)aProgram parentBlock:(TQNodeBlock *)aParentBlock
{
	if(_literalType)
		return _literalType;

	Type *i8PtrTy = aProgram.llInt8PtrTy;
	Type *intTy   = aProgram.llIntTy;

	std::vector<Type*> fields;
	fields.push_back(i8PtrTy); // isa
	fields.push_back(intTy);   // flags
	fields.push_back(intTy);   // reserved
	fields.push_back(i8PtrTy); // invoke(void *blk, ...)
	fields.push_back([self _blockDescriptorTypeInProgram:aProgram]);

	// Fields for captured vars
	for(int i = 0; i < [aParentBlock.locals count]; ++i)
		fields.push_back(i8PtrTy);

	_literalType = StructType::get(aProgram.llModule->getContext(), fields, true);
	return _literalType;
}

- (llvm::Type *)_byRefTypeInProgram:(TQProgram *)aProgram
{
	static Type *byRefType = NULL;
	if(byRefType)
		return byRefType;

	Type *i8PtrTy = aProgram.llInt8PtrTy;
	Type *intTy  = aProgram.llIntTy;

	byRefType = StructType::create("struct.__block_descriptor",
	                               i8PtrTy, i8PtrTy, intTy, intTy, i8PtrTy, NULL);
	//byRefType = PointerType::getUnqual(byRefType);
	return byRefType;
}


#pragma mark - Code generationi


struct dummy {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    void * foo;    // imported variables
};
// Descriptor is a constant struct describing all instances of this block
- (llvm::Constant *)_generateBlockDescriptorInProgram:(TQProgram *)aProgram
{
	if(_blockDescriptor)
		return _blockDescriptor;

	llvm::Module *mod = aProgram.llModule;
	SmallVector<llvm::Constant*, 6> elements;

	// reserved
	elements.push_back(llvm::ConstantInt::get( aProgram.llInt64Ty, 0));  // TODO: Use 32bit on x86

	// Size
	elements.push_back(llvm::ConstantInt::get(aProgram.llInt64Ty, sizeof(struct dummy))); // TODO: Use actual size

	// TODO: Add Copy helper
	// TODO: Add Dispose helper

	// Signature
	//elements.push_back(ConstantExpr::getBitCast((GlobalVariable*)_builder->CreateGlobalString([[self signature]
	//UTF8String]), aProgram.llInt8PtrTy));

	// GC Layout (unused in objc 2)
	//elements.push_back(llvm::Constant::getNullValue(aProgram.llInt8PtrTy));

	llvm::Constant *init = llvm::ConstantStruct::getAnon(elements);

	llvm::GlobalVariable *global = new llvm::GlobalVariable(*mod, init->getType(), true,
	                                llvm::GlobalValue::InternalLinkage,
	                                init, "__tq_block_descriptor_tmp");

	_blockDescriptor = llvm::ConstantExpr::getBitCast(global, [self _blockDescriptorTypeInProgram:aProgram]);
	return _blockDescriptor;
}

// Captures a parent block variable by wrapping it in a byref struct
- (llvm::Value *)_captureLocal:(TQNode *)aLocal fromParent:(TQNodeBlock *)aParent
{
	NSLog(@"------- Capturing %@ from %p", aLocal, aParent);
	return NULL;
}

// The block literal is a stack allocated struct representing a single instance of this block
- (llvm::Value *)_generateBlockLiteralInProgram:(TQProgram *)aProgram parentBlock:(TQNodeBlock *)aParentBlock
{
	Module *mod = aProgram.llModule;
	IRBuilder<> *pBuilder = aParentBlock.builder;

	Type *i8PtrTy = aProgram.llInt8PtrTy;
	Type *i8PtrPtrTy = aProgram.llInt8PtrPtrTy;
	Type *intTy   = aProgram.llIntTy;

	// Build the block struct
	int BlockHeaderSize = 5;
	//llvm::Constant *fields[BlockHeaderSize];
	std::vector<Constant *> fields;

	// isa
	Value *isaPtr;
	if(mod->getNamedValue("_NSConcreteStackBlock"))
		isaPtr = llvm::ConstantExpr::getBitCast(mod->getNamedValue("_NSConcreteStackBlock"), i8PtrPtrTy);
	else
		isaPtr = new llvm::GlobalVariable(*mod, i8PtrTy, false,
		                     llvm::GlobalValue::ExternalLinkage,
		                     0, "_NSConcreteStackBlock", 0,
		                     false, 0);
	Constant *temp = (Constant*)isaPtr;
	isaPtr =  pBuilder->CreateBitCast(isaPtr, i8PtrTy);

	// __flags
	int flags = 0;//TQ_BLOCK_HAS_SIGNATURE;// | TQ_BLOCK_HAS_COPY_DISPOSE;
	//if (blockInfo.UsesStret) flags |= TQ_BLOCK_USE_STRET;
	Value *invoke = pBuilder->CreateBitCast(_function, i8PtrTy, "invokePtr");
	Constant *descriptor = [self _generateBlockDescriptorInProgram:aProgram];

	IRBuilder<> entryBuilder(&aParentBlock.function->getEntryBlock(), aParentBlock.function->getEntryBlock().begin());
	Type *literalTy = [self _blockLiteralTypeInProgram:aProgram parentBlock:aParentBlock];
	AllocaInst *alloca = entryBuilder.CreateAlloca(literalTy, 0, "block");
	alloca->setAlignment(8);

	pBuilder->CreateStore(isaPtr,                         pBuilder->CreateStructGEP(alloca, 0 , "block.isa"));
	pBuilder->CreateStore(ConstantInt::get(intTy, flags), pBuilder->CreateStructGEP(alloca, 1, "block.flags"));
	pBuilder->CreateStore(ConstantInt::get(intTy, 0),     pBuilder->CreateStructGEP(alloca, 2, "block.reserved"));
	pBuilder->CreateStore(invoke,                         pBuilder->CreateStructGEP(alloca, 3 , "block.invoke"));
	pBuilder->CreateStore(descriptor,                     pBuilder->CreateStructGEP(alloca, 4 , "block.descriptor"));

	// Now that we've initialized the basic block info, we need to capture the variables in the parent block scope
	if(aParentBlock) {
		int captureStartIdx = 4;
		for(NSString *name in aParentBlock.locals) {
			if([_locals objectForKey:name])
				continue; // Arguments to this block override locals in the parent (Not that  you should write code like that)

			Value *capturedLocal = [self _captureLocal:[aParentBlock.locals objectForKey:name] fromParent:aParentBlock];
			NSString *fieldName = [NSString stringWithFormat:@"block.%@", name];

			//pBuilder->CreateStore(isaPtr, pBuilder->CreateStructGEP(alloca, captureStartIdx++, [fieldName UTF8String]));
		}
	}

	//return pBuilder->CreateBitCast(alloca, i8PtrTy);
	return pBuilder->CreateCall(aProgram.objc_retainBlock, pBuilder->CreateBitCast(alloca, i8PtrTy));
}

// Copies the captured variables when this block is copied to the heap
- (llvm::Function *)_generateCopyHelperInProgram:(TQProgram *)aProgram
{
	// void (*copy_helper)(void *dst, void *src)
	return NULL;
}

// Releases the captured variables when this block's retain count reaches 0
- (llvm::Function *)_generateDisposeHelperInProgram:(TQProgram *)aProgram
{
	// void (*dispose_helper)(void *src)
	return NULL;
}

// Invokes the body of this block
- (llvm::Function *)_generateInvokeInProgram:(TQProgram *)aProgram error:(NSError **)aoErr
{
	if(_function)
		return _function;

	static int blockId = -1; // TODO: implement this in a proper fashion
	++blockId;

	llvm::PointerType *int8PtrTy = aProgram.llInt8PtrTy;

	// Build the invoke function
	std::vector<Type *> paramTypes(_arguments.count, int8PtrTy);
	FunctionType* funType = FunctionType::get(int8PtrTy, paramTypes, false); // TODO: Support variadics

	llvm::Module *mod = aProgram.llModule;

	const char *funName = [[NSString stringWithFormat:@"__tq_block_invoke_%d", blockId] UTF8String];

	_function = mod->getFunction(funName);
	if (!_function) {
		_function = Function::Create(funType, GlobalValue::ExternalLinkage, funName, mod);
		_function->setCallingConv(CallingConv::C);
	}

	_basicBlock = BasicBlock::Create(mod->getContext(), "entry", _function, 0);
	_builder = new IRBuilder<>(_basicBlock);

	// Load the arguments
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

	// Load captured variables
	// TODO

	Value *val;
	for(TQNode *node in _statements) {
		val = [node generateCodeInProgram:aProgram block:self error:aoErr];
		if(!val) {
			NSLog(@"Error: %@", *aoErr);
			return NULL;
		}
	}

	if(!_basicBlock->getTerminator())
		ReturnInst::Create(mod->getContext(), ConstantPointerNull::get(int8PtrTy), _basicBlock);

	return _function;
}


// Generates a block on the stack
- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
	TQAssert(!_basicBlock && !_function, @"Tried to regenerate code for block %@", _name);
	llvm::Module *mod = aProgram.llModule;

	// First we must

	if(![self _generateInvokeInProgram:aProgram error:aoErr])
		return NULL;

	Value *literal = [self _generateBlockLiteralInProgram:aProgram parentBlock:aBlock];

	return literal;
}
@end


#pragma mark - Root block

@implementation TQNodeRootBlock

- (id)init
{
	if(!(self = [super init]))
		return nil;

	// No arguments for the root block ([super init] adds the block itself as an arg)
	[self.arguments removeAllObjects];

	return self;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
	// The root block is just a function that executes the body of the program
	// so we only need to create&return it's invocation function
	return [self _generateInvokeInProgram:aProgram error:aoErr];
}

@end
