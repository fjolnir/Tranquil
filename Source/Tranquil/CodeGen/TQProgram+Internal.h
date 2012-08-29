// Defines private methods and those that require a C++ compiler (So that client apps don't need to be compiled as ObjC++ even if they only perform basic execution)

#import <Tranquil/CodeGen/TQProgram.h>
#import <Tranquil/CodeGen/TQProgram+LLVMUtils.h>
#include <llvm/Support/IRBuilder.h>
#include <llvm/Analysis/DIBuilder.h>
#include <llvm/ExecutionEngine/JIT.h>
#include <llvm/ExecutionEngine/JITMemoryManager.h>
#include <llvm/ExecutionEngine/JITEventListener.h>
#include <llvm/ExecutionEngine/GenericValue.h>

#define DW_LANG_Tranquil 0x9c40
#define TRANQUIL_DEBUG_DESCR "Tranquil α"

@class TQNodeRootBlock, NSString, NSError;

@interface TQProgram () {
    llvm::ExecutionEngine *_executionEngine;
}
@property(readonly) llvm::Module *llModule;
@property(readonly) llvm::Value *cliArgGlobal;

#pragma mark - Global values
@property(readonly) llvm::GlobalVariable *globalQueue;

#pragma mark - Debug info related
@property(readonly) llvm::DIBuilder *debugBuilder;

- (TQNodeRootBlock *)_rootFromFile:(NSString *)aPath error:(NSError **)aoErr;
- (TQNodeRootBlock *)_parseScript:(NSString *)aScript error:(NSError **)aoErr;
- (NSString *)_resolveImportPath:(NSString *)aPath;

- (void)insertLogUsingBuilder:(llvm::IRBuilder<> *)aBuilder withStr:(NSString *)txt;
- (llvm::Value *)getGlobalStringPtr:(NSString *)aStr withBuilder:(llvm::IRBuilder<> *)aBuilder;
- (llvm::Value *)getGlobalStringPtr:(NSString *)aStr inBlock:(TQNodeBlock *)aBlock;
@end

