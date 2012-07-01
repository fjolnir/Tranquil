#ifndef _TQ_PROGRAM_H_
#define _TQ_PROGRAM_H_

#include <TQNodeBlock.h>
#include <llvm/Support/IRBuilder.h>
#include <Foundation/NSObject.h>

@interface TQProgram : NSObject
@property(readwrite, retain) NSString *name;
@property(readwrite, retain) TQNodeBlock *root;
@property(readonly) llvm::Module *llModule;
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


+ (TQProgram *)programWithName:(NSString *)aName;
- (id)initWithName:(NSString *)aName;
- (BOOL)run;

@end

#endif
