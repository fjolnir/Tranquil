#import <Tranquil/CodeGen/TQNode.h>
#include "TQNodeReturn.h"
#include "../Runtime/TQRuntime.h"
#include <llvm/Support/IRBuilder.h>
#include <llvm/Analysis/DebugInfo.h>

@class TQNodeArgumentDef, TQNodeVariable, TQNodeIntVariable, TQNodeLongVariable;

// A block definition ({ :arg | body })
@interface TQNodeBlock : TQNode {
    @protected
    llvm::Function *_function;
    llvm::Constant *_blockDescriptor;
    llvm::Type *_literalType;
    NSString *_retType, *_invokeName;
    NSMutableArray *_argTypes;
}
@property(readwrite, retain) NSString *invokeName, *retType;
@property(readwrite, assign) BOOL isCompactBlock; // Was the block written in the form of `expr` ?
@property(readwrite, assign) BOOL isTranquilBlock; // Should the block be treated as a tranquil block? (arg count check etc)
@property(readwrite, retain) TQNodeBlock *parent;
@property(readwrite, copy) NSMutableArray *arguments, *argTypes;
@property(readwrite, copy, nonatomic) NSMutableArray *statements, *cleanupStatements;
@property(readwrite, retain) NSMutableDictionary *locals, *capturedVariables;
@property(readwrite, retain) TQNodeIntVariable *nonLocalReturnTarget;
@property(readwrite, retain) TQNodeLongVariable *nonLocalReturnThread;
@property(readwrite, retain) TQNodeVariable *literalPtr; // Anonymous variable containing the address of the block
@property(readwrite, assign) BOOL isVariadic;
@property(readwrite, assign, nonatomic) llvm::BasicBlock *basicBlock;
@property(readwrite, assign, nonatomic) llvm::Function *function;
@property(readwrite, assign, nonatomic) llvm::IRBuilder<> *builder;
@property(readwrite, assign, nonatomic) llvm::Value *dispatchGroup;
@property(readwrite, assign, nonatomic) llvm::DISubprogram debugInfo;
@property(readwrite, assign, nonatomic) llvm::DILexicalBlock debugScope;
@property(readwrite, assign, nonatomic) llvm::DIScope scope;

// This property is only valid when called from a block's subnode within it's generateCode: method
@property(readwrite, assign) llvm::Value *autoreleasePool;

+ (TQNodeBlock *)node;
- (NSString *)signatureInProgram:(TQProgram *)aProgram;
- (NSUInteger)argumentCount;
- (BOOL)addArgument:(TQNodeArgumentDef *)aArgument error:(NSError **)aoErr;
- (void)generateCleanupInProgram:(TQProgram *)aProgram;
- (void)createDispatchGroupInProgram:(TQProgram *)aProgram;
@end

@interface TQNodeRootBlock : TQNodeBlock
@property(readwrite, assign, nonatomic) llvm::DICompileUnit debugUnit;
+ (TQNodeRootBlock *)node;
@end
