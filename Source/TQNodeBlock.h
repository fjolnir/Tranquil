#import "TQNode.h"
#include <llvm/Support/IRBuilder.h>

@class TQNodeArgumentDef;

// A block definition ({ :arg | body })
@interface TQNodeBlock : TQNode
@property(readwrite, retain) TQNodeBlock *parent;
@property(readwrite, copy) NSMutableArray *arguments;
@property(readwrite, copy, nonatomic) NSMutableArray *statements;
@property(readwrite, copy) NSMutableDictionary *locals;
@property(readwrite, copy) NSString *name;
@property(readonly) llvm::BasicBlock *basicBlock;
@property(readonly) llvm::Function *function;
@property(readonly) llvm::IRBuilder<> *builder;

+ (TQNodeBlock *)node;

- (BOOL)addArgument:(TQNodeArgumentDef *)aArgument error:(NSError **)aoError;
@end
