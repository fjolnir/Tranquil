#import <Tranquil/CodeGen/TQProgram.h>
#include <llvm/Support/IRBuilder.h>
#include <llvm/Analysis/DIBuilder.h>
#include <llvm/ExecutionEngine/JIT.h>
#include <llvm/ExecutionEngine/JITMemoryManager.h>
#include <llvm/ExecutionEngine/JITEventListener.h>
#include <llvm/ExecutionEngine/GenericValue.h>

#define DW_LANG_Tranquil 0x9c40
#define TRANQUIL_DEBUG_DESCR "Tranquil α"

@class TQNodeRootBlock, NSString, NSError;

@interface TQProgram (LLVMUtils)
#pragma mark - Cached types
// void
@property(readonly) llvm::Type *llVoidTy;
// i8, i16, i32, and i64
@property(readonly) llvm::Type *llInt8Ty, *llInt16Ty, *llInt32Ty, *llInt64Ty;
// float, double
@property(readonly) llvm::Type *llFloatTy, *llDoubleTy, *llFPTy;
// int
@property(readonly) llvm::Type *llIntTy;
// intptr_t, size_t, and ptrdiff_t, which we assume are the same size.
@property(readonly) llvm::Type *llIntPtrTy, *llSizeTy, *llPtrDiffTy;
// void* in address space 0
@property(readonly) llvm::PointerType *llVoidPtrTy, *llInt8PtrTy;
// void** in address space 0
@property(readonly) llvm::PointerType *llVoidPtrPtrTy, *llInt8PtrPtrTy;
@property(readonly) llvm::StructType *llVaListTy;

// The width of a pointer into the generic address space.
@property(readonly) unsigned char llPointerWidthInBits;
// The size and alignment of a pointer into the generic address space.
@property(readonly) unsigned char llPointerAlignInBytes, llPointerSizeInBytes;

#pragma mark - Cached functions
@property(readonly) llvm::Function *objc_msgSend, *objc_msgSend_fixup, *objc_msgSendSuper, *objc_storeWeak,
    *objc_loadWeak, *objc_destroyWeak, *objc_retain, *objc_release, *objc_allocateClassPair,
    *objc_registerClassPair, *class_replaceMethod, *objc_getClass,
    *sel_registerName, *_Block_copy, *objc_retainAutoreleaseReturnValue, *objc_autoreleaseReturnValue,
    *_Block_object_assign, *_Block_object_dispose, *imp_implementationWithBlock,
    *object_getClass, *TQPrepareObjectForReturn, *objc_autorelease, *objc_storeStrong, *TQStoreStrong,
    *objc_autoreleasePoolPush, *objc_autoreleasePoolPop, *TQSetValueForKey, *TQValueForKey,
    *TQGetOrCreateClass, *TQObjectsAreEqual, *TQObjectsAreNotEqual, *TQObjectGetSuperClass,
    *TQVaargsToArray, *TQUnboxObject, *TQBoxValue, *tq_msgSend, *tq_msgSend_noBoxing, *objc_retainAutoreleasedReturnValue,
    *TQInitializeRuntime, *TQCliArgsToArray,
    *dispatch_get_global_queue, *dispatch_group_create, *dispatch_release, *dispatch_group_wait,
    *dispatch_group_notify, *dispatch_group_async, *objc_sync_enter, *objc_sync_exit,
    *TQFloatFitsInTaggedPointer;

- (llvm::Type *)llvmTypeFromEncoding:(const char *)aEncoding;
@end
