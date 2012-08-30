#import "TQProgram.h"
#import "TQProgram+LLVMUtils.h"
#import "TQProgram+Internal.h"
#import "../Shared/TQDebug.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <llvm/Transforms/IPO/PassManagerBuilder.h>
#import <llvm/Target/TargetData.h>

#include <llvm/Module.h>
#include <llvm/DerivedTypes.h>
#include <llvm/Constants.h>
#include <llvm/CallingConv.h>
#include <llvm/Instructions.h>
#include <llvm/PassManager.h>
#include <llvm/Analysis/Verifier.h>
#include <llvm/Target/TargetData.h>
#include <llvm/Target/TargetData.h>
#include <llvm/Target/TargetMachine.h>
#include <llvm/Target/TargetOptions.h>
#include <llvm/Transforms/Scalar.h>
#include <llvm/Transforms/IPO.h>
#include <llvm/Support/raw_ostream.h>
#if !defined(LLVM_TOT)
# include <llvm/Support/system_error.h>
#endif
#include <llvm/Support/PrettyStackTrace.h>
#include <llvm/Support/MemoryBuffer.h>
#include <llvm/Intrinsics.h>
#include <llvm/Bitcode/ReaderWriter.h>
#include <llvm/LLVMContext.h>
#include <llvm/Support/ToolOutputFile.h>
#include <llvm/Support/TargetRegistry.h>
#include <llvm/Support/Host.h>
#include <llvm/Support/TypeBuilder.h>
#include "llvm/ADT/Statistic.h"

using namespace llvm;

@implementation TQProgram (LLVMUtils)
@dynamic llVoidTy, llInt8Ty, llInt16Ty, llInt32Ty, llInt64Ty,
    llFloatTy, llDoubleTy, llFPTy, llIntTy, llIntPtrTy, llSizeTy,
    llPtrDiffTy, llVoidPtrTy, llInt8PtrTy, llVoidPtrPtrTy,
    llInt8PtrPtrTy, llPointerWidthInBits, llPointerAlignInBytes,
    llPointerSizeInBytes;
@dynamic objc_msgSend, objc_msgSend_fixup, objc_msgSendSuper,
    objc_storeWeak, objc_loadWeak, objc_allocateClassPair,
    objc_registerClassPair, objc_destroyWeak,
    class_replaceMethod, sel_registerName,
    objc_getClass, objc_retain, objc_release,
    _Block_copy, _Block_object_assign,
    _Block_object_dispose, imp_implementationWithBlock,
    object_getClass, TQPrepareObjectForReturn,
    objc_autorelease, objc_autoreleasePoolPush,
    objc_autoreleasePoolPop, TQSetValueForKey,
    TQValueForKey, TQGetOrCreateClass,
    TQObjectsAreEqual, TQObjectsAreNotEqual, TQObjectGetSuperClass,
    TQVaargsToArray, TQUnboxObject,
    TQBoxValue, tq_msgSend, objc_retainAutoreleaseReturnValue,
    objc_autoreleaseReturnValue, objc_retainAutoreleasedReturnValue,
    objc_storeStrong, TQInitializeRuntime, TQCliArgsToArray,
    dispatch_get_global_queue, dispatch_group_create,
    dispatch_release, dispatch_group_wait,
    dispatch_group_notify, dispatch_group_async,
    objc_sync_enter, objc_sync_exit;



#pragma mark - Types
- (llvm::Type *)llVoidTy
{
    llvm::LLVMContext &ctx = self.llModule->getContext();
    return llvm::Type::getVoidTy(ctx);
}
- (llvm::Type *)llInt8Ty
{
    llvm::LLVMContext &ctx = self.llModule->getContext();
    return llvm::Type::getInt8Ty(ctx);
}
- (llvm::Type *)llInt16Ty
{
    llvm::LLVMContext &ctx = self.llModule->getContext();
    return llvm::Type::getInt16Ty(ctx);
}
- (llvm::Type *)llInt32Ty
{
    llvm::LLVMContext &ctx = self.llModule->getContext();
    return llvm::Type::getInt32Ty(ctx);
}
- (llvm::Type *)llInt64Ty
{
    llvm::LLVMContext &ctx = self.llModule->getContext();
    return llvm::Type::getInt64Ty(ctx);
}
- (llvm::Type *)llFloatTy
{
    llvm::LLVMContext &ctx = self.llModule->getContext();
    return llvm::Type::getFloatTy(ctx);
}
- (llvm::Type *)llDoubleTy
{
    llvm::LLVMContext &ctx = self.llModule->getContext();
    return llvm::Type::getDoubleTy(ctx);
}
- (llvm::Type *)llFPTy
{
    #ifdef __LP64__
    return self.llDoubleTy;
    #else
    return self.llFloatTy;
    #endif
}
- (unsigned char)llPointerWidthInBits
{
    return 64;
}
- (unsigned char)llPointerAlignInBytes
{
    return 8;
}
- (llvm::Type *)llIntTy
{
    llvm::LLVMContext &ctx = self.llModule->getContext();
    return TypeBuilder<int, false>::get(ctx); //llvm::IntegerType::get(ctx, 32);
}
- (llvm::Type *)llIntPtrTy
{
    llvm::LLVMContext &ctx = self.llModule->getContext();
   return llvm::IntegerType::get(ctx, self.llPointerWidthInBits);
}
- (llvm::PointerType *)llInt8PtrTy
{
    llvm::LLVMContext &ctx = self.llModule->getContext();
    return TypeBuilder<char*, false>::get(ctx); //self.llInt8Ty->getPointerTo(0);
}
- (llvm::PointerType *)llInt8PtrPtrTy
{
    return self.llInt8PtrTy->getPointerTo(0);
}

#pragma mark - Functions
#define FunAccessor(name, type) \
- (llvm::Function *) name \
{ \
    Function *func_##name = self.llModule->getFunction(#name); \
    if(!func_##name) { \
        func_##name = Function::Create([self _##type], GlobalValue::ExternalLinkage, #name, self.llModule); \
        func_##name->setCallingConv(CallingConv::C); \
    } \
    return func_##name; \
}

- (llvm::FunctionType *)_ft_i8Ptr__i8Ptr_i8Ptr_sizeT
{
    // id(id, char*, int64)
    llvm::LLVMContext &ctx = self.llModule->getContext();
    std::vector<Type*> args_i8Ptr_i8Ptr_sizeT;
    args_i8Ptr_i8Ptr_sizeT.push_back(self.llInt8PtrTy);
    args_i8Ptr_i8Ptr_sizeT.push_back(self.llInt8PtrTy);
    args_i8Ptr_i8Ptr_sizeT.push_back(llvm::TypeBuilder<size_t, false>::get(ctx));
    return FunctionType::get(self.llInt8PtrTy, args_i8Ptr_i8Ptr_sizeT, false);
}

- (llvm::FunctionType *)_ft_void__void
{
    // void(void)
    std::vector<Type*> args_void;
    return FunctionType::get(self.llVoidTy, args_void, false);
}
- (llvm::FunctionType *)_ft_void__i8Ptr
{
    // void(id)
    std::vector<Type*> args_i8Ptr;
    args_i8Ptr.push_back(self.llInt8PtrTy);
    return FunctionType::get(self.llVoidTy, args_i8Ptr, false);
}
- (llvm::FunctionType *)_ft_void__i8Ptr_int
{
    // void(id, int)
    std::vector<Type*> args_i8Ptr_int;
    args_i8Ptr_int.push_back(self.llInt8PtrTy);
    args_i8Ptr_int.push_back(self.llIntTy);
    return FunctionType::get(self.llVoidTy, args_i8Ptr_int, false);

}
- (llvm::FunctionType *)_ft_void__i8Ptr_i8Ptr_int
{
    // void(id, id, int)
    std::vector<Type*> args_i8Ptr_i8Ptr_int;
    args_i8Ptr_i8Ptr_int.push_back(self.llInt8PtrTy);
    args_i8Ptr_i8Ptr_int.push_back(self.llInt8PtrTy);
    args_i8Ptr_i8Ptr_int.push_back(self.llIntTy);
    return FunctionType::get(self.llVoidTy, args_i8Ptr_i8Ptr_int, false);
}
- (llvm::FunctionType *)_ft_i8__i8Ptr_i8Ptr_sizeT_i8_i8Ptr
{
    // BOOL(Class, char *, size_t, uint8_t, char *)
    llvm::LLVMContext &ctx = self.llModule->getContext();
    std::vector<Type*> args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr;
    args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr.push_back(self.llInt8PtrTy);
    args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr.push_back(self.llInt8PtrTy);
    args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr.push_back(llvm::TypeBuilder<size_t, false>::get(ctx));
    args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr.push_back(self.llInt8Ty);
    args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr.push_back(self.llInt8PtrTy);
    return FunctionType::get(self.llInt8Ty, args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr, false);
}
- (llvm::FunctionType *)_ft_i8__i8Ptr_i8Ptr_i8Ptr_i8Ptr
{
    // BOOL(Class, SEL, IMP, char *)
    std::vector<Type*> args_i8Ptr_i8Ptr_i8Ptr_i8Ptr;
    args_i8Ptr_i8Ptr_i8Ptr_i8Ptr.push_back(self.llInt8PtrTy);
    args_i8Ptr_i8Ptr_i8Ptr_i8Ptr.push_back(self.llInt8PtrTy);
    args_i8Ptr_i8Ptr_i8Ptr_i8Ptr.push_back(self.llInt8PtrTy);
    args_i8Ptr_i8Ptr_i8Ptr_i8Ptr.push_back(self.llInt8PtrTy);
    return FunctionType::get(self.llInt8Ty, args_i8Ptr_i8Ptr_i8Ptr_i8Ptr, false);
}
- (llvm::FunctionType *)_ft_i8ptr__i8ptr_i8ptr_variadic
{
    // id(id, char*, ...)
    std::vector<Type*> args_i8Ptr_i8Ptr_variadic;
    args_i8Ptr_i8Ptr_variadic.push_back(self.llInt8PtrTy);
    args_i8Ptr_i8Ptr_variadic.push_back(self.llInt8PtrTy);
    return FunctionType::get(self.llInt8PtrTy, args_i8Ptr_i8Ptr_variadic, true);
}
- (llvm::FunctionType *)_ft_i8Ptr__i8PtrPtr_i8Ptr
{
    // id(id*, id)
    std::vector<Type*> args_i8PtrPtr_i8Ptr;
    args_i8PtrPtr_i8Ptr.push_back(self.llInt8PtrPtrTy);
    args_i8PtrPtr_i8Ptr.push_back(self.llInt8PtrTy);
    return FunctionType::get(self.llInt8PtrTy, args_i8PtrPtr_i8Ptr, false);
}
- (llvm::FunctionType *)_ft_i8Ptr__i8Ptr_i8Ptr
{
    // id(id, id)
    std::vector<Type*> args_i8Ptr_i8Ptr;
    args_i8Ptr_i8Ptr.push_back(self.llInt8PtrTy);
    args_i8Ptr_i8Ptr.push_back(self.llInt8PtrTy);
    return FunctionType::get(self.llInt8PtrTy, args_i8Ptr_i8Ptr, false);
}
- (llvm::FunctionType *)_ft_i8Ptr__i8Ptr_i8Ptr_i8ptr
{
    // id(id, id, id)
    std::vector<Type*> args_i8Ptr_i8Ptr_i8ptr;
    args_i8Ptr_i8Ptr_i8ptr.push_back(self.llInt8PtrTy);
    args_i8Ptr_i8Ptr_i8ptr.push_back(self.llInt8PtrTy);
    args_i8Ptr_i8Ptr_i8ptr.push_back(self.llInt8PtrTy);
    return FunctionType::get(self.llInt8PtrTy, args_i8Ptr_i8Ptr_i8ptr, false);
}
- (llvm::FunctionType *)_ft_void__i8PtrPtr_i8Ptr
{
    // void(id*, id)
    std::vector<Type*> args_i8PtrPtr_i8Ptr;
    args_i8PtrPtr_i8Ptr.push_back(self.llInt8PtrPtrTy);
    args_i8PtrPtr_i8Ptr.push_back(self.llInt8PtrTy);
    return FunctionType::get(self.llVoidTy, args_i8PtrPtr_i8Ptr, false);
}
- (llvm::FunctionType *)_ft_void__i8Ptr_i8Ptr_i8Ptr
{
    // void(id, id, id)
    std::vector<Type*> args_i8Ptr_i8Ptr_i8Ptr;
    args_i8Ptr_i8Ptr_i8Ptr.push_back(self.llInt8PtrTy);
    args_i8Ptr_i8Ptr_i8Ptr.push_back(self.llInt8PtrTy);
    args_i8Ptr_i8Ptr_i8Ptr.push_back(self.llInt8PtrTy);
    return FunctionType::get(self.llVoidTy, args_i8Ptr_i8Ptr_i8Ptr, false);
}
- (llvm::FunctionType *)_ft_void__i8Ptr_i8Ptr
{
    // void(id, id)
    std::vector<Type*> args_i8Ptr_i8Ptr;
    args_i8Ptr_i8Ptr.push_back(self.llInt8PtrTy);
    args_i8Ptr_i8Ptr.push_back(self.llInt8PtrTy);
    return FunctionType::get(self.llVoidTy, args_i8Ptr_i8Ptr, false);
}
- (llvm::FunctionType *)_ft_i8Ptr__i8PtrPtr
{
    // id(id*)
    std::vector<Type*> args_i8PtrPtr;
    args_i8PtrPtr.push_back(self.llInt8PtrPtrTy);
    return FunctionType::get(self.llInt8PtrTy, args_i8PtrPtr, false);
}
- (llvm::FunctionType *)_ft_void__i8PtrPtr
{
    // void(id*)
    std::vector<Type*> args_i8PtrPtr;
    args_i8PtrPtr.push_back(self.llInt8PtrPtrTy);
    return FunctionType::get(self.llVoidTy, args_i8PtrPtr, false);
}
- (llvm::FunctionType *)_ft_i8Ptr__i8Ptr
{
    // id(id)
    std::vector<Type*> args_i8Ptr;
    args_i8Ptr.push_back(self.llInt8PtrTy);
    return FunctionType::get(self.llInt8PtrTy, args_i8Ptr, false);
}
- (llvm::FunctionType *)_ft_i8Ptr__void
{
    // id()
    std::vector<Type*> args_empty;
    return FunctionType::get(self.llInt8PtrTy, args_empty, false);
}
- (llvm::FunctionType *)_ft_int__i8Ptr
{
    // int(id)
    std::vector<Type*> args_i8Ptr;
    args_i8Ptr.push_back(self.llInt8PtrTy);
    return FunctionType::get(self.llIntTy, args_i8Ptr, false);
}
- (llvm::FunctionType *)_ft_i8Ptr__i32_i8PtrPtr
{
    // id(int, void**)
    std::vector<Type*> args_int_i8PtrPtr;
    args_int_i8PtrPtr.push_back(self.llIntTy);
    args_int_i8PtrPtr.push_back(self.llInt8PtrPtrTy);
    return FunctionType::get(self.llInt8PtrTy, args_int_i8PtrPtr, false);
}
- (llvm::FunctionType *)_ft_i8Ptr__i64_i64
{
    // void*(long, long)
    std::vector<Type*> args_i64_i64;
    args_i64_i64.push_back(self.llInt64Ty);
    args_i64_i64.push_back(self.llInt64Ty);
    return FunctionType::get(self.llInt8PtrTy, args_i64_i64, false);
}
- (llvm::FunctionType *)_ft_i64__i8Ptr_i64
{
    // long(void*, long)
    std::vector<Type*> args_i8Ptr_i64;
    args_i8Ptr_i64.push_back(self.llInt8PtrTy);
    args_i8Ptr_i64.push_back(self.llInt64Ty);
    return FunctionType::get(self.llInt64Ty, args_i8Ptr_i64, false);
}


FunAccessor(objc_allocateClassPair, ft_i8Ptr__i8Ptr_i8Ptr_sizeT)
FunAccessor(objc_registerClassPair, ft_void__i8Ptr)
FunAccessor(class_replaceMethod, ft_i8__i8Ptr_i8Ptr_i8Ptr_i8Ptr)
FunAccessor(imp_implementationWithBlock, ft_i8Ptr__i8Ptr)
FunAccessor(object_getClass, ft_i8Ptr__i8Ptr)
FunAccessor(objc_msgSend, ft_i8ptr__i8ptr_i8ptr_variadic)
FunAccessor(objc_msgSend_fixup, ft_i8ptr__i8ptr_i8ptr_variadic)
FunAccessor(objc_msgSendSuper, ft_i8ptr__i8ptr_i8ptr_variadic)
FunAccessor(objc_retain, ft_i8Ptr__i8Ptr)
FunAccessor(objc_retainAutoreleaseReturnValue, ft_i8Ptr__i8Ptr)
FunAccessor(objc_retainAutoreleasedReturnValue, ft_i8Ptr__i8Ptr)
FunAccessor(objc_autoreleaseReturnValue, ft_i8Ptr__i8Ptr)
FunAccessor(objc_release, ft_void__i8Ptr)
FunAccessor(objc_autorelease, ft_i8Ptr__i8Ptr)
FunAccessor(sel_registerName, ft_i8Ptr__i8Ptr)
FunAccessor(objc_getClass, ft_i8Ptr__i8Ptr)
FunAccessor(_Block_copy, ft_i8Ptr__i8Ptr)
FunAccessor(_Block_object_assign, ft_void__i8Ptr_i8Ptr_int)
FunAccessor(_Block_object_dispose, ft_void__i8Ptr_int)
FunAccessor(TQPrepareObjectForReturn, ft_i8Ptr__i8Ptr)
FunAccessor(objc_autoreleasePoolPush, ft_i8Ptr__void)
FunAccessor(objc_autoreleasePoolPop, ft_void__i8Ptr)
FunAccessor(objc_storeStrong, ft_i8Ptr__i8PtrPtr_i8Ptr)
FunAccessor(TQSetValueForKey, ft_void__i8Ptr_i8Ptr_i8Ptr)
FunAccessor(TQValueForKey, ft_i8Ptr__i8Ptr_i8Ptr)
FunAccessor(TQGetOrCreateClass, ft_i8Ptr__i8Ptr_i8Ptr)
FunAccessor(TQObjectsAreEqual, ft_i8Ptr__i8Ptr_i8Ptr)
FunAccessor(TQObjectsAreNotEqual, ft_i8Ptr__i8Ptr_i8Ptr)
FunAccessor(TQObjectGetSuperClass, ft_i8Ptr__i8Ptr)
FunAccessor(TQVaargsToArray, ft_i8Ptr__i8Ptr)
FunAccessor(TQUnboxObject,  ft_void__i8Ptr_i8Ptr_i8Ptr)
FunAccessor(TQBoxValue,  ft_i8Ptr__i8Ptr_i8Ptr)
FunAccessor(tq_msgSend, ft_i8ptr__i8ptr_i8ptr_variadic)
FunAccessor(TQInitializeRuntime, ft_void__void)
FunAccessor(TQCliArgsToArray, ft_i8Ptr__i32_i8PtrPtr)
FunAccessor(dispatch_get_global_queue, ft_i8Ptr__i64_i64)
FunAccessor(dispatch_group_create, ft_i8Ptr__void)
FunAccessor(dispatch_release, ft_void__i8Ptr)
FunAccessor(dispatch_group_wait, ft_i64__i8Ptr_i64)
FunAccessor(dispatch_group_notify, ft_void__i8Ptr_i8Ptr_i8Ptr)
FunAccessor(dispatch_group_async, ft_void__i8Ptr_i8Ptr_i8Ptr)
FunAccessor(objc_sync_enter, ft_int__i8Ptr)
FunAccessor(objc_sync_exit, ft_int__i8Ptr)

#pragma mark -

- (llvm::Type *)llvmTypeFromEncoding:(const char *)aEncoding
{
    switch(*aEncoding) {
        case _C_CONST:
            return [self llvmTypeFromEncoding:aEncoding+1];
        case _C_ID:
        case _C_CLASS:
        case _C_SEL:
        case _C_CHARPTR:
        case _TQ_C_LAMBDA_B:
            return self.llInt8PtrTy;
        case _C_DBL:
            return self.llDoubleTy;
        case _C_FLT:
            return self.llFloatTy;
        case _C_INT:
            return self.llIntTy;
        case _C_SHT:
            return self.llInt16Ty;
        case _C_CHR:
            return self.llInt8Ty;
        case _C_BOOL:
            return self.llInt8Ty;
        case _C_LNG:
            return self.llInt64Ty;
        case _C_LNG_LNG:
            return self.llInt64Ty;
        case _C_UINT:
            return self.llIntTy;
        case _C_USHT:
            return self.llInt16Ty;
        case _C_ULNG:
            return self.llInt64Ty;
        case _C_ULNG_LNG:
            return self.llInt64Ty;
        case _C_VOID:
            return self.llVoidTy;
        case _C_STRUCT_B: {
            const char *field = strstr(aEncoding, "=") + 1;
            assert((uintptr_t)field > 1);
            std::vector<Type*> fields;
            while(*field != _C_STRUCT_E) {
                fields.push_back([self llvmTypeFromEncoding:field]);
                field = TQGetSizeAndAlignment(field, NULL, NULL);
            }
            return StructType::get(self.llModule->getContext(), fields);
        }
        case _C_UNION_B:
            TQLog(@"unions -> llvm not yet supported %s", aEncoding);
            exit(1);
        break;
        case _C_ARY_B: {
            unsigned count;
            ++aEncoding; // Skip past the '['
            assert(isdigit(*aEncoding));
            count = atoi(aEncoding);
            // Move on to the enclosed type
            while(isdigit(*aEncoding)) ++aEncoding;
            Type *enclosedType = [self llvmTypeFromEncoding:aEncoding];
            return ArrayType::get(enclosedType, count);
        } break;
        case _C_PTR: {
            if(*(aEncoding + 1) == _C_PTR || *(aEncoding + 1) == _C_CHARPTR || *(aEncoding + 1) == _C_ID)
                return self.llInt8PtrPtrTy;
            else
                return self.llInt8PtrTy;
        }
        default:
            [NSException raise:NSGenericException
                        format:@"Unsupported type %c!", *aEncoding];
            return NULL;
    }
}
@end

