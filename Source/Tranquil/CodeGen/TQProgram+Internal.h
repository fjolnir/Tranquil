// Defines private methods and those that require a C++ compiler (So that client apps don't need to be compiled as ObjC++ even if they only perform basic execution)

#import <Tranquil/CodeGen/TQProgram.h>
#include <llvm/Support/IRBuilder.h>
#include <llvm/Analysis/DIBuilder.h>


#define DW_LANG_Tranquil 0x9c40
#define TRANQUIL_DEBUG_DESCR "Tranquil α"

@class TQNodeRootBlock, NSString, NSError;

@interface TQProgram ()
@property(readonly) llvm::Module *llModule;
@property(readonly) llvm::Value *cliArgGlobal;

#pragma mark - Global values
@property(readonly) llvm::GlobalVariable *globalQueue;

#pragma mark - Debug info related
@property(readonly) llvm::DIBuilder *debugBuilder;

#pragma mark - Cached types
// void
@property(readonly) llvm::Type *llVoidTy;
// i8, i16, i32, and i64
@property(readonly) llvm::IntegerType *llInt8Ty, *llInt16Ty, *llInt32Ty, *llInt64Ty;
// float, double
@property(readonly) llvm::Type *llFloatTy, *llDoubleTy, *llFPTy;
// int
@property(readonly) llvm::IntegerType *llIntTy;
// intptr_t, size_t, and ptrdiff_t, which we assume are the same size.
@property(readonly) llvm::IntegerType *llIntPtrTy, *llSizeTy, *llPtrDiffTy;
// void* in address space 0
@property(readonly) llvm::PointerType *llVoidPtrTy, *llInt8PtrTy;
// void** in address space 0
@property(readonly) llvm::PointerType *llVoidPtrPtrTy, *llInt8PtrPtrTy;
// The width of a pointer into the generic address space.
@property(readonly) unsigned char llPointerWidthInBits;
// The size and alignment of a pointer into the generic address space.
@property(readonly) unsigned char llPointerAlignInBytes, llPointerSizeInBytes;

@property(readonly) llvm::Type *llBlockDescriptorTy, *llBlockLiteralType;

#pragma mark - Cached functions
@property(readonly) llvm::Function *objc_msgSend, *objc_msgSend_fixup, *objc_msgSendSuper, *objc_storeWeak,
    *objc_loadWeak, *objc_destroyWeak, *objc_retain, *objc_release, *objc_allocateClassPair,
    *objc_registerClassPair, *class_replaceMethod, *objc_getClass,
    *sel_registerName, *_Block_copy, *objc_retainAutoreleaseReturnValue, *objc_autoreleaseReturnValue,
    *_Block_object_assign, *_Block_object_dispose, *imp_implementationWithBlock,
    *object_getClass, *TQPrepareObjectForReturn, *objc_autorelease, *objc_storeStrong,
    *objc_autoreleasePoolPush, *objc_autoreleasePoolPop, *TQSetValueForKey, *TQValueForKey,
    *TQGetOrCreateClass, *TQObjectsAreEqual, *TQObjectsAreNotEqual, *TQObjectGetSuperClass,
    *TQVaargsToArray, *TQUnboxObject, *TQBoxValue, *tq_msgSend, *objc_retainAutoreleasedReturnValue,
    *TQInitializeRuntime, *TQCliArgsToArray,
    *dispatch_get_global_queue, *dispatch_group_create, *dispatch_release, *dispatch_group_wait,
    *dispatch_group_notify, *dispatch_group_async, *objc_sync_enter, *objc_sync_exit;

- (TQNodeRootBlock *)_rootFromFile:(NSString *)aPath error:(NSError **)aoErr;
- (TQNodeRootBlock *)_parseScript:(NSString *)aScript error:(NSError **)aoErr;
- (NSString *)_resolveImportPath:(NSString *)aPath;

- (void)insertLogUsingBuilder:(llvm::IRBuilder<> *)aBuilder withStr:(NSString *)txt;
- (llvm::Value *)getGlobalStringPtr:(NSString *)aStr withBuilder:(llvm::IRBuilder<> *)aBuilder;
- (llvm::Value *)getGlobalStringPtr:(NSString *)aStr inBlock:(TQNodeBlock *)aBlock;

- (llvm::Type *)llvmTypeFromEncoding:(const char *)aEncoding;
@end
