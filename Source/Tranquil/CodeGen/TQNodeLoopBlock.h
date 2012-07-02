#import "TQNodeBlock.h"
#include <llvm/IRBuilder.h>

@interface TQNodeWhileBlock : TQNodeBlock
@property(readwrite, retain) TQNode *condition;
@property(readwrite, assign) llvm::BasicBlock *loopStartBlock, *loopEndBlock;

+ (TQNodeWhileBlock *)node;
- (llvm::Value *)generateTestExpressionInProgram:(TQProgram *)aProgram
                                     withBuilder:(llvm::IRBuilder<> *)aBuilder
                                           value:(llvm::Value *)aValue;
@end

@interface TQNodeUntilBlock : TQNodeWhileBlock
@end

@interface TQNodeBreak : TQNode
+ (TQNodeBreak *)node;
@end

@interface TQNodeSkip : TQNode
+ (TQNodeSkip *)node;
@end
