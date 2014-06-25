#import <Tranquil/CodeGen/TQNode.h>
#import "TQNodeReturn.h"
#import "../Runtime/TQRuntime.h"
#include <llvm/IRBuilder.h>
#include <llvm/DebugInfo.h>

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
@property(nonatomic, readwrite, retain) NSString *invokeName, *retType;
@property(nonatomic, readwrite, assign) BOOL isCompactBlock; // Was the block written in the form of `expr` ?
@property(nonatomic, readwrite, assign) BOOL isTranquilBlock; // Should the block be treated as a tranquil block? (arg count check etc)
@property(nonatomic, readwrite, retain) TQNodeBlock *parent;
@property(nonatomic, readwrite, copy) NSMutableArray *arguments, *argTypes;
@property(nonatomic, readwrite, copy, nonatomic) NSMutableArray *statements, *cleanupStatements;
@property(nonatomic, readwrite, retain) NSMutableDictionary *locals, *capturedVariables;
@property(nonatomic, readwrite, retain) TQNodeIntVariable *nonLocalReturnTarget;
@property(nonatomic, readwrite, retain) TQNodeLongVariable *nonLocalReturnThread;
@property(nonatomic, readwrite, retain) TQNodeVariable *literalPtr; // Anonymous variable containing the address of the block
@property(nonatomic, readwrite, assign) BOOL isVariadic;
@property(nonatomic, readwrite, assign, nonatomic) llvm::BasicBlock *basicBlock;
@property(nonatomic, readwrite, assign, nonatomic) llvm::Function *function;
@property(nonatomic, readwrite, assign, nonatomic) llvm::IRBuilder<> *builder;
@property(nonatomic, readwrite, assign, nonatomic) llvm::Value *dispatchGroup;
@property(nonatomic, readwrite, assign, nonatomic) llvm::DISubprogram debugInfo;
@property(nonatomic, readwrite, assign, nonatomic) llvm::DILexicalBlock debugScope;
@property(nonatomic, readwrite, assign, nonatomic) llvm::DIScope scope;

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
@property(readwrite, assign, nonatomic) llvm::DIFile file;
+ (TQNodeRootBlock *)node;
@end
