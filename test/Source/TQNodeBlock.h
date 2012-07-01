#import "TQNode.h"
#include <llvm/Support/IRBuilder.h>

@class TQNodeArgument;

// A block definition ({ :arg | body })
@interface TQNodeBlock : TQNode
@property(readwrite, copy) NSMutableArray *arguments;
@property(readwrite, copy) NSMutableArray *statements;
@property(readwrite, copy) NSMutableDictionary *locals;
@property(readwrite, copy) NSString *name;
@property(readonly) llvm::BasicBlock *basicBlock;
@property(readonly) llvm::Function *function;
@property(readonly) llvm::IRBuilder<> *builder;

+ (TQNodeBlock *)node;

- (BOOL)addArgument:(TQNodeArgument *)aArgument error:(NSError **)aoError;
@end
