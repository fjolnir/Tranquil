#import "TQNodeBlock.h"
#include <llvm/Support/IRBuilder.h>

@interface TQNodeIfBlock : TQNodeBlock
@property(readwrite, retain) TQNode *condition;
@property(readwrite, copy) NSMutableArray *elseBlockStatements;

+ (TQNodeIfBlock *)node;
- (llvm::Value *)generateTestExpressionInProgram:(TQProgram *)aProgram
                                           block:(TQNodeBlock *)aBlock
                                           value:(llvm::Value *)aValue;
@end

@interface TQNodeUnlessBlock : TQNodeIfBlock
@end
