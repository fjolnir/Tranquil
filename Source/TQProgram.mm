#include "TQProgram.h"
#include "TQNode.h"

using namespace llvm;


@implementation TQProgram
@synthesize  root=_root, name=_name, llModule=_llModule, irBuilder=_irBuilder;
@synthesize llVoidTy=_llVoidTy, llInt8Ty=_llInt8Ty, llInt16Ty=_llInt16Ty, llInt32Ty=_llInt32Ty, llInt64Ty=_llInt64Ty, llFloatTy=_llFloatTy, llDoubleTy=_llDoubleTy, llIntTy=_llIntTy, llIntPtrTy=_llIntPtrTy, llSizeTy=_llSizeTy, llPtrDiffTy=_llPtrDiffTy, llVoidPtrTy=_llVoidPtrTy, llInt8PtrTy=_llInt8PtrTy, llVoidPtrPtrTy=_llVoidPtrPtrTy, llInt8PtrPtrTy=_llInt8PtrPtrTy, llPointerWidthInBits=_llPointerWidthInBits, llPointerAlignInBytes=_llPointerAlignInBytes, llPointerSizeInBytes=_llPointerSizeInBytes;
@synthesize llBlockDescriptorTy=_blockDescriptorTy, llBlockLiteralType=_blockLiteralType;
@synthesize objc_msgSend=_func_objc_msgSend, objc_storeStrong=_func_objc_storeStrong, objc_storeWeak=_func_objc_storeWeak, objc_loadWeak=_func_objc_loadWeak, objc_allocateClassPair=_func_objc_allocateClassPair, objc_registerClassPair=_func_objc_registerClassPair, objc_destroyWeak=_func_objc_destroyWeak, class_addIvar=_func_class_addIvar, class_addMethod=_func_class_addMethod, sel_registerName=_func_sel_registerName, sel_getName=_func_sel_getName, objc_getClass=_func_objc_getClass, objc_retain=_func_objc_retain, objc_release=_func_objc_release;

+ (TQProgram *)programWithName:(NSString *)aName
{
	return [[[self alloc] initWithName:aName] autorelease];
}

- (id)initWithName:(NSString *)aName
{
	if(!(self = [super init]))
		return nil;

	_name = [aName retain];
	_llModule = new Module([_name UTF8String], getGlobalContext());
	llvm::LLVMContext &ctx = _llModule->getContext();
	_irBuilder = new IRBuilder<>(ctx);

	// Cache the types
	_llVoidTy               = llvm::Type::getVoidTy(ctx);
	_llInt8Ty               = llvm::Type::getInt8Ty(ctx);
	_llInt16Ty              = llvm::Type::getInt16Ty(ctx);
	_llInt32Ty              = llvm::Type::getInt32Ty(ctx);
	_llInt64Ty              = llvm::Type::getInt64Ty(ctx);
	_llFloatTy              = llvm::Type::getFloatTy(ctx);
	_llDoubleTy             = llvm::Type::getDoubleTy(ctx);
	_llPointerWidthInBits   = 64;
	_llPointerAlignInBytes  = 8;
	_llIntTy                = llvm::IntegerType::get(ctx, 32);
	_llIntPtrTy             = llvm::IntegerType::get(ctx, _llPointerWidthInBits);
	_llInt8PtrTy            = _llInt8Ty->getPointerTo(0);
	_llInt8PtrPtrTy         = _llInt8PtrTy->getPointerTo(0);

	// Block types
	_blockDescriptorTy = llvm::StructType::create("struct.__tq_block_descriptor",
	                          _llInt64Ty, _llInt64Ty, NULL);
	Type *blockDescriptorPtrTy = llvm::PointerType::getUnqual(_blockDescriptorTy);
	_blockLiteralType = llvm::StructType::create("struct.__block_literal_generic",
	                              _llInt8PtrTy, _llIntTy, _llIntTy, _llInt8PtrTy, blockDescriptorPtrTy, NULL);

	// Cache commonly used functions
	#define DEF_EXTERNAL_FUN(name, type) \
	_func_##name = _llModule->getFunction(#name); \
	if(!_func_##name) { \
		_func_##name = Function::Create((type), GlobalValue::ExternalLinkage, #name, _llModule); \
		_func_##name->setCallingConv(CallingConv::C); \
	}

	Type *size_tTy = llvm::TypeBuilder<size_t, false>::get(ctx);

	// id(id, char*, int64)
	std::vector<Type*> args_i8Ptr_i8Ptr_sizeT;
	args_i8Ptr_i8Ptr_sizeT.push_back(_llInt8PtrTy);
	args_i8Ptr_i8Ptr_sizeT.push_back(_llInt8PtrTy);
	args_i8Ptr_i8Ptr_sizeT.push_back(size_tTy);
	FunctionType *ft_void__i8Ptr_i8Ptr_sizeT = FunctionType::get(_llVoidTy, args_i8Ptr_i8Ptr_sizeT, false);

	// void(id)
	std::vector<Type*> args_i8Ptr;
	args_i8Ptr.push_back(_llInt8PtrTy);
	FunctionType *ft_void__i8Ptr = FunctionType::get(_llVoidTy, args_i8Ptr, false);

	// BOOL(Class, char *, size_t, uint8_t, char *)
	std::vector<Type*> args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr;
	args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr.push_back(_llInt8PtrTy);
	args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr.push_back(_llInt8PtrTy);
	args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr.push_back(size_tTy);
	args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr.push_back(_llInt8Ty);
	args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr.push_back(_llInt8PtrTy);
	FunctionType *ft_i8__i8Ptr_i8Ptr_sizeT_i8_i8Ptr = FunctionType::get(_llInt8Ty, args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr, false);

	// BOOL(Class, SEL, IMP, char *)
	std::vector<Type*> args_i8Ptr_i8Ptr_i8Ptr_i8Ptr;
	args_i8Ptr_i8Ptr_i8Ptr_i8Ptr.push_back(_llInt8PtrTy);
	args_i8Ptr_i8Ptr_i8Ptr_i8Ptr.push_back(_llInt8PtrTy);
	args_i8Ptr_i8Ptr_i8Ptr_i8Ptr.push_back(_llInt8PtrTy);
	args_i8Ptr_i8Ptr_i8Ptr_i8Ptr.push_back(_llInt8PtrTy);
	FunctionType *ft_i8__i8Ptr_i8Ptr_i8Ptr_i8Ptr = FunctionType::get(_llInt8Ty, args_i8Ptr_i8Ptr_i8Ptr_i8Ptr, false);

	// id(id, char*, ...)
	std::vector<Type*> args_i8Ptr_i8Ptr_variadic;
	args_i8Ptr_i8Ptr_variadic.push_back(_llInt8PtrTy);
	args_i8Ptr_i8Ptr_variadic.push_back(_llInt8PtrTy);
	FunctionType *ft_i8ptr__i8ptr_i8ptr_variadic = FunctionType::get(_llInt8PtrTy, args_i8Ptr_i8Ptr_variadic, true);

	// id(id*, id)
	std::vector<Type*> args_i8PtrPtr_i8Ptr;
	args_i8PtrPtr_i8Ptr.push_back(_llInt8PtrPtrTy);
	args_i8PtrPtr_i8Ptr.push_back(_llInt8PtrTy);
	FunctionType *ft_i8Ptr__i8PtrPtr_i8Ptr = FunctionType::get(_llInt8PtrTy, args_i8PtrPtr_i8Ptr, false);

	// void(id*, id)
	FunctionType *ft_void__i8PtrPtr_i8Ptr = FunctionType::get(_llVoidTy, args_i8PtrPtr_i8Ptr, false);

	// id(id*)
	std::vector<Type*> args_i8PtrPtr;
	args_i8PtrPtr.push_back(_llInt8PtrPtrTy);
	FunctionType *ft_i8Ptr__i8PtrPtr = FunctionType::get(_llInt8PtrTy, args_i8PtrPtr, false);

	// void(id*)
	FunctionType *ft_void__i8PtrPtr = FunctionType::get(_llVoidTy, args_i8PtrPtr, false);

	// id(id)
	FunctionType *ft_i8Ptr__i8Ptr = FunctionType::get(_llInt8PtrTy, args_i8Ptr, false);

	DEF_EXTERNAL_FUN(objc_allocateClassPair, ft_void__i8Ptr_i8Ptr_sizeT)
	DEF_EXTERNAL_FUN(objc_registerClassPair, ft_void__i8Ptr)
	DEF_EXTERNAL_FUN(class_addIvar, ft_i8__i8Ptr_i8Ptr_sizeT_i8_i8Ptr)
	DEF_EXTERNAL_FUN(class_addMethod, ft_i8__i8Ptr_i8Ptr_i8Ptr_i8Ptr)
	DEF_EXTERNAL_FUN(objc_msgSend, ft_i8ptr__i8ptr_i8ptr_variadic)
	DEF_EXTERNAL_FUN(objc_storeStrong, ft_void__i8PtrPtr_i8Ptr)
	DEF_EXTERNAL_FUN(objc_storeWeak, ft_i8Ptr__i8PtrPtr_i8Ptr)
	DEF_EXTERNAL_FUN(objc_loadWeak, ft_i8Ptr__i8PtrPtr)
	DEF_EXTERNAL_FUN(objc_destroyWeak, ft_void__i8PtrPtr)
	DEF_EXTERNAL_FUN(objc_retain, ft_i8Ptr__i8Ptr)
	DEF_EXTERNAL_FUN(objc_release, ft_void__i8Ptr)
	DEF_EXTERNAL_FUN(sel_registerName, ft_i8Ptr__i8Ptr)
	DEF_EXTERNAL_FUN(sel_getName, ft_i8Ptr__i8Ptr)
	DEF_EXTERNAL_FUN(objc_getClass, ft_i8Ptr__i8Ptr)

#undef DEF_EXTERNAL_FUN

	return self;
}

- (void)dealloc
{
	delete _irBuilder;
	delete _llModule;
	[super dealloc];
}

- (BOOL)run
{
	InitializeNativeTarget();

	NSError *err = nil;
	_root.name = @"root";
	[_root generateCodeInProgram:self block:nil error:&err];
	if(err) {
		NSLog(@"Error: %@", err);
		//return NO;
	}

	// Output LLVM - IR
	verifyModule(*_llModule, PrintMessageAction);
	PassManager PM;
	PM.add(createPrintModulePass(&outs()));
	PM.run(*_llModule);

	// Execute program
	ExecutionEngine *engine = EngineBuilder(_llModule).create();

	//std::vector<GenericValue> noargs;
	//GenericValue val = engine->runFunction(_root.function, noargs);
	//void *ret = val.PointerVal;
	//NSLog(@"'root' ret:  %p: %@\n", ret, ret ? ret : nil);
	//return YES;

	id(*rootPtr)() = (id(*)())engine->getPointerToFunction(_root.function);

	id ret = rootPtr();
	printf("--\n");
	NSLog(@"'root' retval:  %p: %@ (%@)\n", ret, ret ? ret : nil, [ret class]);
	
	if([ret isKindOfClass:NSClassFromString(@"NSBlock")]) {
		id (^test)(id obj) = ret;
		NSNumber *num = test([NSNumber numberWithInt:1337]);
		NSLog(@"Block retval: %@ (%@)", num, [num class]);
	}

	return YES;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<prog@\n%@\n}>", _root];
}

#pragma mark - ARC Operations

//- ()retainValue:(llvm::Value *)aValue
//{
//}
@end


