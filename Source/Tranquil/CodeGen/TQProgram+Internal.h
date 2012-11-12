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

@class TQNodeRootBlock, OFString, TQError;

@interface TQProgram () {
    llvm::ExecutionEngine *_executionEngine;
}
@property(readonly) OFMutableArray *evaluatedPaths; // Reset after root finishes

@property(readonly) llvm::Module *llModule;
@property(readonly) llvm::Value *cliArgGlobal;

#pragma mark - Global values
@property(readonly) llvm::GlobalVariable *globalQueue;

#pragma mark - Debug info related
@property(readonly) llvm::DIBuilder *debugBuilder;

- (TQNodeRootBlock *)_rootFromFile:(OFString *)aPath error:(TQError **)aoErr;
- (TQNodeRootBlock *)_parseScript:(OFString *)aScript error:(TQError **)aoErr;
- (OFString *)_resolveImportPath:(OFString *)aPath;

- (void)insertLogUsingBuilder:(llvm::IRBuilder<> *)aBuilder withStr:(OFString *)txt;
- (llvm::Value *)getGlobalStringPtr:(OFString *)aStr withBuilder:(llvm::IRBuilder<> *)aBuilder;
- (llvm::Value *)getGlobalStringPtr:(OFString *)aStr inBlock:(TQNodeBlock *)aBlock;
@end

