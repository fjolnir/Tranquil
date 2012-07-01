#import "TQNodeVariable.h"
#import "TQProgram.h"
#import <llvm/Support/IRBuilder.h>

using namespace llvm;

@implementation TQNodeVariable
@synthesize name=_name, alloca=_alloca;

+ (TQNodeVariable *)nodeWithName:(NSString *)aName
{
	return [[[self alloc] initWithName:aName] autorelease];
}

- (id)initWithName:(NSString *)aName
{
	if(!(self = [super init]))
		return nil;

	_name = [aName retain];

	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<var@ %@>", _name];
}

- (NSUInteger)hash
{
	return [_name hash];
}

- (void)dealloc
{
	[_name release];
	[super dealloc];
}

- (llvm::Value *)_getForwardingInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock
{
	//static NSMapTable *forwards;
	//if(!forwards)
		//forwards = [NSCreateMapTable(NSNonRetainedObjectMapKeyCallBacks, NSOwnedPointerMapValueCallBacks, 16) retain];
	Value *forwarding;
	//if((forwarding = (Value*)NSMapGet(forwards, aBlock)) != NULL)
		//return forwarding;
	
	NSLog(@"GETTING FORWARDING -----------------------------");
	IRBuilder<> *builder = aBlock.builder;
	forwarding = builder->CreateLoad(builder->CreateStructGEP(_alloca, 1), [self _llvmRegisterName:@"forwarding"]);
	forwarding = builder->CreateBitCast(forwarding, PointerType::getUnqual([self captureStructTypeInProgram:aProgram]),
	"forwardingCast");
	forwarding =  builder->CreateLoad(builder->CreateStructGEP(forwarding, 6));
	//NSMapInsert(forwards, aBlock, forwarding);
	return forwarding;
}

- (llvm::Type *)captureStructTypeInProgram:(TQProgram *)aProgram
{
	static Type *captureType = NULL;
	if(captureType)
		return captureType;

	Type *i8PtrTy = aProgram.llInt8PtrTy;
	Type *intTy   = aProgram.llIntTy;

	captureType = StructType::create("struct._block_byref",
	                                 i8PtrTy, // isa
	                                 i8PtrTy, // forwarding
	                                 intTy,   // flags (refcount)
	                                 intTy,   // size ( = sizeof(id))
	                                 i8PtrTy, // byref_keep(void *dest, void *src)
	                                 i8PtrTy, // byref_dispose(void *)
	                                 i8PtrTy, // Captured variable (id)
	                                 NULL);
	return captureType;
}

- (llvm::Function *)_generateKeepHelperInProgram:(TQProgram *)aProgram
{
	static Function *keepHelper;
	if(keepHelper)
		return keepHelper;

	Type *int8PtrTy = aProgram.llInt8PtrTy;
	Type *intTy = aProgram.llIntTy;
	std::vector<Type *> paramTypes;
	paramTypes.push_back(int8PtrTy);
	paramTypes.push_back(int8PtrTy);

	FunctionType* funType = FunctionType::get(aProgram.llVoidTy, paramTypes, false);

	llvm::Module *mod = aProgram.llModule;

	const char *funName = [[NSString stringWithFormat:@"__tq_byref_obj_keep_helper"] UTF8String];
	keepHelper = Function::Create(funType, GlobalValue::ExternalLinkage, funName, mod);
	keepHelper->setCallingConv(CallingConv::C);

	BasicBlock *basicBlock = BasicBlock::Create(mod->getContext(), "entry", keepHelper, 0);
	IRBuilder<> *builder = new IRBuilder<>(basicBlock);

	Type *byrefPtrTy = PointerType::getUnqual([self captureStructTypeInProgram:aProgram]);

	// Load the passed arguments
	AllocaInst *dstAlloca = builder->CreateAlloca(int8PtrTy);
	AllocaInst *srcAlloca = builder->CreateAlloca(int8PtrTy);

	Function::arg_iterator args = keepHelper->arg_begin();
	builder->CreateStore(args, dstAlloca);
	builder->CreateStore(++args, srcAlloca);

	Value *dstByRef = builder->CreateBitCast(builder->CreateLoad(dstAlloca), byrefPtrTy);
	Value *srcByRef = builder->CreateBitCast(builder->CreateLoad(srcAlloca), byrefPtrTy);
	Value *flags = ConstantInt::get(intTy, TQ_BLOCK_BYREF_CALLER | TQ_BLOCK_FIELD_IS_OBJECT);

	Value *destAddr  = builder->CreateBitCast(builder->CreateStructGEP(dstByRef, 6), int8PtrTy);
	Value *srcPtr = builder->CreateLoad(builder->CreateStructGEP(srcByRef, 6));

	builder->CreateCall3(aProgram._Block_object_assign, destAddr, srcPtr, flags);
	builder->CreateRetVoid();
	return keepHelper;
}

- (llvm::Function *)_generateDisposeHelperInProgram:(TQProgram *)aProgram
{
	static Function *disposeHelper;
	if(disposeHelper)
		return disposeHelper;

	Type *int8PtrTy = aProgram.llInt8PtrTy;
	std::vector<Type *> paramTypes;
	paramTypes.push_back(int8PtrTy);

	FunctionType* funType = FunctionType::get(aProgram.llVoidTy, paramTypes, false);

	llvm::Module *mod = aProgram.llModule;

	const char *funName = [[NSString stringWithFormat:@"__tq_byref_obj_dispose_helper"] UTF8String];
	disposeHelper = Function::Create(funType, GlobalValue::ExternalLinkage, funName, mod);
	disposeHelper->setCallingConv(CallingConv::C);

	BasicBlock *basicBlock = BasicBlock::Create(mod->getContext(), "entry", disposeHelper, 0);
	IRBuilder<> *builder = new IRBuilder<>(basicBlock);

	//Type *byrefPtrTy = PointerType::getUnqual([self captureStructTypeInProgram:aProgram]);

	// Load the passed arguments
	//AllocaInst *dstAlloca = builder->CreateAlloca(int8PtrTy); 

	//Function::arg_iterator args = function->arg_begin();
	//builder->CreateStore(args, dstAlloca);

	//Value *dstByRef = builder->CreateBitCast(builder->CreateLoad(dstAlloca), byrefPtrTy);
	//Value *flags = ConstantInt::get(intTy, TQ_BLOCK_BYREF_CALLER | TQ_BLOCK_FIELD_IS_OBJECT);

	//Value *srcPtr = builder->CreateLoad(builder->CreateStructGEP(srcByRef, 6));

	//builder->CreateCall3(aProgram._Block_object_assign, destAddr, srcPtr, flags);

	builder->CreateRetVoid();
	return disposeHelper;
}

- (const char *)_llvmRegisterName:(NSString *)subname
{
	return [[NSString stringWithFormat:@"%@.%@", _name, subname] UTF8String];
}

- (llvm::Value *)createStorageInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                 error:(NSError **)aoError
{
	if(_alloca)
		return _alloca;

	IRBuilder<> *builder = aBlock.builder;
	TQNodeVariable *existingVar = nil;
	if((existingVar = [aBlock.locals objectForKey:_name]) && existingVar != self) {
		if(![existingVar generateCodeInProgram:aProgram block:aBlock error:aoError])
			return NULL;
		_alloca = existingVar.alloca;
		return _alloca;
	} else
		[aBlock.locals setObject:self forKey:_name];

	Type *intTy   = aProgram.llIntTy;
	Type *i8PtrTy = aProgram.llInt8PtrTy;

	Type *byRefType = [self captureStructTypeInProgram:aProgram];
	AllocaInst *alloca = builder->CreateAlloca(byRefType, 0, [self _llvmRegisterName:@"alloca"]);
	Value *keepHelper = builder->CreateBitCast([self _generateKeepHelperInProgram:aProgram], i8PtrTy);
	Value *disposeHelper = builder->CreateBitCast([self _generateDisposeHelperInProgram:aProgram], i8PtrTy);

	
	// Initialize the variable to nil
	builder->CreateStore(builder->CreateBitCast(alloca, i8PtrTy),        builder->CreateStructGEP(alloca, 1, [self _llvmRegisterName:@"forwarding"]));
	builder->CreateStore(ConstantInt::get(intTy, TQ_BLOCK_HAS_COPY_DISPOSE), builder->CreateStructGEP(alloca, 2, [self _llvmRegisterName:@"flags"]));
	Constant *size = ConstantExpr::getTruncOrBitCast(ConstantExpr::getSizeOf(byRefType), intTy);
	builder->CreateStore(size,                                           builder->CreateStructGEP(alloca, 3, [self _llvmRegisterName:@"size"]));
	builder->CreateStore(keepHelper,                                     builder->CreateStructGEP(alloca, 4, [self _llvmRegisterName:@"byref_keep"]));
	builder->CreateStore(disposeHelper,                                  builder->CreateStructGEP(alloca, 5, [self _llvmRegisterName:@"byref_dispose"]));
	builder->CreateStore(ConstantPointerNull::get(aProgram.llInt8PtrTy), builder->CreateStructGEP(alloca, 6, [self _llvmRegisterName:@"marked_variable"]));

	_alloca = alloca;
	return _alloca;
}
- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                 error:(NSError **)aoError
{
	if(_alloca)
		return [self _getForwardingInProgram:aProgram block:aBlock];

	if(![self createStorageInProgram:aProgram block:aBlock error:aoError])
		return NULL;

	return [self _getForwardingInProgram:aProgram block:aBlock];
}

- (llvm::Value *)store:(llvm::Value *)aValue
             inProgram:(TQProgram *)aProgram
                 block:(TQNodeBlock *)aBlock
                 error:(NSError **)aoError
{
	if(!_alloca) {
		if(![self createStorageInProgram:aProgram block:aBlock error:aoError])
			return NULL;
	}
	IRBuilder<> *builder = aBlock.builder;
	Value *forwarding = builder->CreateLoad(builder->CreateStructGEP(_alloca, 1), [self _llvmRegisterName:@"forwarding"]);
	forwarding = builder->CreateBitCast(forwarding, PointerType::getUnqual([self captureStructTypeInProgram:aProgram]));

	return aBlock.builder->CreateStore(aValue, builder->CreateStructGEP(forwarding, 6));
}
@end
