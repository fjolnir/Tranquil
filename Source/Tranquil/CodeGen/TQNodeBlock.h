#import <Tranquil/CodeGen/TQNode.h>
#include "TQNodeReturn.h"
#include "../Runtime/TQRuntime.h"
#include <llvm/Support/IRBuilder.h>

// A block definition ({ :arg | body })
@interface TQNodeBlock : TQNode {
    llvm::Constant *_blockDescriptor;
    llvm::Type *_literalType;
    NSMutableDictionary *_capturedVariables;
}
@property(readwrite, retain) TQNodeBlock *parent;
@property(readwrite, copy) NSMutableArray *arguments;
@property(readwrite, copy, nonatomic) NSMutableArray *statements;
@property(readwrite, retain) NSMutableDictionary *locals;
@property(readwrite, copy) NSString *name;
@property(readwrite, assign) llvm::BasicBlock *basicBlock;
@property(readwrite, assign) llvm::Function *function;
@property(readwrite, assign) llvm::IRBuilder<> *builder;

// This property is only valid when called from a block's subnode within it's generateCode: method
@property(readwrite, assign) llvm::Value *autoreleasePool;

+ (TQNodeBlock *)node;
- (NSString *)signature;
- (BOOL)addArgument:(NSString *)aArgument error:(NSError **)aoError;
@end

@interface TQNodeRootBlock : TQNodeBlock
@end
