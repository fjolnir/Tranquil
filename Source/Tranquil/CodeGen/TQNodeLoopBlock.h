#import "TQNodeBlock.h"
#include <llvm/Support/IRBuilder.h>

// Set on a block to know which while loop to break out of
extern void * const TQCurrLoopKey;

@interface TQNodeWhileBlock : TQNode
@property(readwrite, retain) TQNode *condition;
@property(readwrite, copy, nonatomic) NSMutableArray *statements, *cleanupStatements;
@property(readwrite, assign) llvm::BasicBlock *loopStartBlock, *loopEndBlock;

+ (TQNodeWhileBlock *)node;
+ (TQNodeWhileBlock *)nodeWithCondition:(TQNode *)aCond statements:(NSMutableArray *)aStmt;
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
