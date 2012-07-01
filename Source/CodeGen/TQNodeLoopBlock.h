#import "TQNodeBlock.h"
#include <llvm/Support/IRBuilder.h>

@interface TQNodeWhileBlock : TQNodeBlock
@property(readwrite, retain) TQNode *condition;

+ (TQNodeWhileBlock *)node;
- (llvm::Value *)generateTestExpressionInProgram:(TQProgram *)aProgram
                                     withBuilder:(llvm::IRBuilder<> *)aBuilder
                                           value:(llvm::Value *)aValue;
@end

@interface TQNodeUntilBlock : TQNodeWhileBlock
@end
