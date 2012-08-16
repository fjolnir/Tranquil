#import <Tranquil/CodeGen/TQNode.h>
#include "TQNodeReturn.h"
#include "../Runtime/TQRuntime.h"
#include <llvm/Support/IRBuilder.h>

@class TQNodeArgumentDef;

// A block definition ({ :arg | body })
@interface TQNodeBlock : TQNode {
    @protected
    llvm::Function *_function;
    llvm::Constant *_blockDescriptor;
    llvm::Type *_literalType;
    NSString *_retType;
    NSMutableArray *_argTypes;
}
@property(readwrite, assign) BOOL isCompactBlock; // Was the block written in the form of `expr` ?
@property(readwrite, assign) BOOL isTranquilBlock; // Should the block be treated as a tranquil block? (arg count check etc)
@property(readwrite, retain) TQNodeBlock *parent;
@property(readwrite, copy) NSMutableArray *arguments;
@property(readwrite, copy, nonatomic) NSMutableArray *statements;
@property(readwrite, retain) NSMutableDictionary *locals, *capturedVariables;
@property(readwrite, assign) BOOL isVariadic;
@property(readwrite, assign) llvm::BasicBlock *basicBlock;
@property(readwrite, assign) llvm::Function *function;
@property(readwrite, assign) llvm::IRBuilder<> *builder;

// This property is only valid when called from a block's subnode within it's generateCode: method
@property(readwrite, assign) llvm::Value *autoreleasePool;

+ (TQNodeBlock *)node;
- (NSString *)signatureInProgram:(TQProgram *)aProgram;
- (NSUInteger)argumentCount;
- (BOOL)addArgument:(TQNodeArgumentDef *)aArgument error:(NSError **)aoErr;
@end

@interface TQNodeRootBlock : TQNodeBlock
+ (TQNodeRootBlock *)node;
@end
