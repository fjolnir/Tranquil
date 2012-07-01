#include "TQProgram.h"
#include "CodeGen/TQNode.h"
#include <llvm/Transforms/IPO/PassManagerBuilder.h>
#import <mach/mach_time.h>
#import "Runtime/TQRuntime.h"
#import <objc/runtime.h>

using namespace llvm;

@implementation TQProgram
@synthesize root=_root, name=_name, llModule=_llModule, irBuilder=_irBuilder;
@synthesize llVoidTy=_llVoidTy, llInt8Ty=_llInt8Ty, llInt16Ty=_llInt16Ty, llInt32Ty=_llInt32Ty, llInt64Ty=_llInt64Ty,
	llFloatTy=_llFloatTy, llDoubleTy=_llDoubleTy, llIntTy=_llIntTy, llIntPtrTy=_llIntPtrTy, llSizeTy=_llSizeTy,
	llPtrDiffTy=_llPtrDiffTy, llVoidPtrTy=_llVoidPtrTy, llInt8PtrTy=_llInt8PtrTy, llVoidPtrPtrTy=_llVoidPtrPtrTy,
	llInt8PtrPtrTy=_llInt8PtrPtrTy, llPointerWidthInBits=_llPointerWidthInBits, llPointerAlignInBytes=_llPointerAlignInBytes,
	llPointerSizeInBytes=_llPointerSizeInBytes;
@synthesize llBlockDescriptorTy=_blockDescriptorTy, llBlockLiteralType=_blockLiteralType;
@synthesize objc_msgSend=_func_objc_msgSend, TQStoreStrongInByref=_func_TQStoreStrongInByref, objc_storeWeak=_func_objc_storeWeak,
	objc_loadWeak=_func_objc_loadWeak, objc_allocateClassPair=_func_objc_allocateClassPair,
	objc_registerClassPair=_func_objc_registerClassPair, objc_destroyWeak=_func_objc_destroyWeak, class_addIvar=_func_class_addIvar,
	class_replaceMethod=_func_class_replaceMethod, sel_registerName=_func_sel_registerName, sel_getName=_func_sel_getName,
	objc_getClass=_func_objc_getClass, TQRetainObject=_func_TQRetainObject, TQReleaseObject=_func_TQReleaseObject,
	_Block_copy=_func__Block_copy, _Block_object_assign=_func__Block_object_assign,
	_Block_object_dispose=_func__Block_object_dispose, imp_implementationWithBlock=_func_imp_implementationWithBlock,
	object_getClass=_func_object_getClass, TQPrepareObjectForReturn=_func_TQPrepareObjectForReturn,
	TQAutoreleaseObject=_func_TQAutoreleaseObject;

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
	_llIntTy                = TypeBuilder<int, false>::get(ctx); //llvm::IntegerType::get(ctx, 32);
	_llIntPtrTy             = llvm::IntegerType::get(ctx, _llPointerWidthInBits);
	_llInt8PtrTy            = TypeBuilder<char*, false>::get(ctx); //_llInt8Ty->getPointerTo(0);
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
	FunctionType *ft_i8Ptr__i8Ptr_i8Ptr_sizeT = FunctionType::get(_llInt8PtrTy, args_i8Ptr_i8Ptr_sizeT, false);

	// void(id)
	std::vector<Type*> args_i8Ptr;
	args_i8Ptr.push_back(_llInt8PtrTy);
	FunctionType *ft_void__i8Ptr = FunctionType::get(_llVoidTy, args_i8Ptr, false);

	// void(id, int)
	std::vector<Type*> args_i8Ptr_int;
	args_i8Ptr_int.push_back(_llInt8PtrTy);
	args_i8Ptr_int.push_back(_llIntTy);
	FunctionType *ft_void__i8Ptr_int = FunctionType::get(_llVoidTy, args_i8Ptr_int, false);

	// void(id, id, int)
	std::vector<Type*> args_i8Ptr_i8Ptr_int;
	args_i8Ptr_i8Ptr_int.push_back(_llInt8PtrTy);
	args_i8Ptr_i8Ptr_int.push_back(_llInt8PtrTy);
	args_i8Ptr_i8Ptr_int.push_back(_llIntTy);
	FunctionType *ft_void__i8Ptr_i8Ptr_int = FunctionType::get(_llVoidTy, args_i8Ptr_i8Ptr_int, false);

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

	// id(id, id)
	std::vector<Type*> args_i8Ptr_i8Ptr;
	args_i8Ptr_i8Ptr.push_back(_llInt8PtrTy);
	args_i8Ptr_i8Ptr.push_back(_llInt8PtrTy);
	FunctionType *ft_i8Ptr__i8Ptr_i8Ptr = FunctionType::get(_llInt8PtrTy, args_i8Ptr_i8Ptr, false);

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

	DEF_EXTERNAL_FUN(objc_allocateClassPair, ft_i8Ptr__i8Ptr_i8Ptr_sizeT)
	DEF_EXTERNAL_FUN(objc_registerClassPair, ft_void__i8Ptr)
	//DEF_EXTERNAL_FUN(class_addIvar, ft_i8__i8Ptr_i8Ptr_sizeT_i8_i8Ptr)
	DEF_EXTERNAL_FUN(class_replaceMethod, ft_i8__i8Ptr_i8Ptr_i8Ptr_i8Ptr)
	DEF_EXTERNAL_FUN(imp_implementationWithBlock, ft_i8Ptr__i8Ptr)
	DEF_EXTERNAL_FUN(object_getClass, ft_i8Ptr__i8Ptr)
	DEF_EXTERNAL_FUN(objc_msgSend, ft_i8ptr__i8ptr_i8ptr_variadic)
	DEF_EXTERNAL_FUN(TQStoreStrongInByref, ft_i8Ptr__i8Ptr_i8Ptr)
	//DEF_EXTERNAL_FUN(objc_storeWeak, ft_i8Ptr__i8PtrPtr_i8Ptr)
	//DEF_EXTERNAL_FUN(objc_loadWeak, ft_i8Ptr__i8PtrPtr)
	//DEF_EXTERNAL_FUN(objc_destroyWeak, ft_void__i8PtrPtr)
	DEF_EXTERNAL_FUN(TQRetainObject, ft_i8Ptr__i8Ptr)
	//DEF_EXTERNAL_FUN(TQReleaseObject, ft_void__i8Ptr)
	DEF_EXTERNAL_FUN(TQAutoreleaseObject, ft_i8Ptr__i8Ptr);
	DEF_EXTERNAL_FUN(sel_registerName, ft_i8Ptr__i8Ptr)
	//DEF_EXTERNAL_FUN(sel_getName, ft_i8Ptr__i8Ptr)
	DEF_EXTERNAL_FUN(objc_getClass, ft_i8Ptr__i8Ptr)
	DEF_EXTERNAL_FUN(_Block_copy, ft_i8Ptr__i8Ptr);
	DEF_EXTERNAL_FUN(_Block_object_assign, ft_void__i8Ptr_i8Ptr_int);
	DEF_EXTERNAL_FUN(_Block_object_dispose, ft_void__i8Ptr_int);
	DEF_EXTERNAL_FUN(TQPrepareObjectForReturn, ft_i8Ptr__i8Ptr);


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
	TQInitializeRuntime();
	InitializeNativeTarget();

	NSError *err = nil;
	_root.name = @"root";
	[_root generateCodeInProgram:self block:nil error:&err];
	if(err) {
		NSLog(@"Error: %@", err);
		return NO;
	}

	// Optimization pass
	//FunctionPassManager fpm = FunctionPassManager(_llModule);
	//PassManagerBuilder builder = PassManagerBuilder();
	//builder.OptLevel = 3;
	//builder.SizeLevel = 2;
	//builder.populateFunctionPassManager(fpm);
	//fpm.run(*_root.function);

	PassManager PM;
	PM.add(createPrintModulePass(&outs()));
	PM.run(*_llModule);

	// Verify that the program is valid
	verifyModule(*_llModule, PrintMessageAction);


	// Compile program
	ExecutionEngine *engine = EngineBuilder(_llModule).create();
	engine->addGlobalMapping(_func_TQPrepareObjectForReturn, (void*)&TQPrepareObjectForReturn);
	engine->addGlobalMapping(_func_TQStoreStrongInByref, (void*)&TQStoreStrongInByref);
	engine->addGlobalMapping(_func_TQRetainObject, (void*)&TQRetainObject);
	engine->addGlobalMapping(_func_TQAutoreleaseObject, (void*)&TQAutoreleaseObject);

	//std::vector<GenericValue> noargs;
	//GenericValue val = engine->runFunction(_root.function, noargs);
	//void *ret = val.PointerVal;
	//NSLog(@"'root' ret:  %p: %@\n", ret, ret ? ret : nil);
	//return YES;

	id(*rootPtr)() = (id(*)())engine->getPointerToFunction(_root.function);


	printf("---------------------\n");
	uint64_t startTime = mach_absolute_time();
	// Execute code
	id ret = rootPtr();

	uint64_t ns = mach_absolute_time() - startTime;
	struct mach_timebase_info timebase;
	mach_timebase_info(&timebase);
	double sec = ns * timebase.numer / timebase.denom / 1000000000.0;

	TQLog(@"Run time: %f sec\n", sec);
	TQLog(@"%p", ret);
	TQLog(@"'root' retval:  %p: %@ (%@)\n", ret, ret ? ret : nil, [ret class]);

	if([ret isKindOfClass:NSClassFromString(@"NSBlock")]) {
		id (^test)(NSString *) = ret;
		NSNumber *num = test(@"hoya");
		TQLog(@"Block retval: %@ (%@)", num, [num class]);
	}
	
	Class fooCls = NSClassFromString(@"Foo");
	if(fooCls)
	{
		[fooCls classMethod];
		id foo = [[fooCls alloc] init];
		[foo instanceMethod:@"Hey I'm objective-c"];
	}
	return YES;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<prog@\n%@\n}>", _root];
}

- (void)insertLogUsingBuilder:(llvm::IRBuilder<> *)aBuilder withStr:(NSString *)txt
{
	std::vector<Type*> nslog_args;
	nslog_args.push_back(_llInt8PtrTy);
	FunctionType *printf_type = FunctionType::get(_llIntTy, nslog_args, true);
	Function *func_printf = _llModule->getFunction("printf");
	if(!func_printf) {
		func_printf = Function::Create(printf_type, GlobalValue::ExternalLinkage, "printf", _llModule);
		func_printf->setCallingConv(CallingConv::C);
	}
	std::vector<Value*> args;
	args.push_back(aBuilder->CreateGlobalStringPtr("> %s\n"));
	args.push_back(aBuilder->CreateGlobalStringPtr([txt UTF8String]));
	aBuilder->CreateCall(func_printf, args);
}

@end


