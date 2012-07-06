#ifndef _TQ_PROGRAM_H_
#define _TQ_PROGRAM_H_

#include <Tranquil/CodeGen/TQNodeBlock.h>
#include <llvm/IRBuilder.h>
#include <Foundation/NSObject.h>

@interface TQProgram : NSObject
@property(readwrite, retain) NSString *name;
@property(readwrite, retain) TQNodeBlock *root;
@property(readwrite, assign) BOOL shouldShowDebugInfo;
@property(readonly) llvm::Module *llModule;
@property(readonly) llvm::IRBuilder<> *irBuilder;

#pragma mark - Cached types
// void
@property(readonly) llvm::Type *llVoidTy;
// i8, i16, i32, and i64
@property(readonly) llvm::IntegerType *llInt8Ty, *llInt16Ty, *llInt32Ty, *llInt64Ty;
// float, double
@property(readonly) llvm::Type *llFloatTy, *llDoubleTy;
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
@property(readonly) llvm::Function *objc_msgSend, *objc_msgSendSuper, *objc_storeWeak,
    *objc_loadWeak, *objc_destroyWeak, *TQRetainObject, *TQReleaseObject, *objc_allocateClassPair,
    *objc_registerClassPair, *class_addIvar, *class_replaceMethod, *objc_getClass,
    *sel_registerName, *sel_getName, *_Block_copy,
    *_Block_object_assign, *_Block_object_dispose, *imp_implementationWithBlock,
    *object_getClass, *TQPrepareObjectForReturn, *TQAutoreleaseObject,
    *objc_autoreleasePoolPush, *objc_autoreleasePoolPop, *TQSetValueForKey, *TQValueForKey,
    *TQGetOrCreateClass, *TQObjectsAreEqual, *TQObjectsAreNotEqual, *TQObjectGetSuperClass,
    *TQVaargsToArray;

#pragma mark - Methods

+ (TQProgram *)programWithName:(NSString *)aName;
- (id)initWithName:(NSString *)aName;
- (BOOL)run;

- (void)insertLogUsingBuilder:(llvm::IRBuilder<> *)aBuilder withStr:(NSString *)txt;
- (llvm::Value *)getGlobalStringPtr:(NSString *)aStr withBuilder:(llvm::IRBuilder<> *)aBuilder;
- (llvm::Value *)getGlobalStringPtr:(NSString *)aStr inBlock:(TQNodeBlock *)aBlock;
@end
#endif
