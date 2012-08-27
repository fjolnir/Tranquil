#import "TQNodeBlock.h"
#include <llvm/Support/IRBuilder.h>

@interface TQNodeIfBlock : TQNode {
    @protected
     NSMutableArray *_ifStatements, *_elseStatements;
}
@property(readwrite, retain) TQNode *condition;
@property(readwrite, copy) NSMutableArray *ifStatements, *elseStatements;

+ (TQNodeIfBlock *)node;
- (llvm::Value *)generateTestExpressionInProgram:(TQProgram *)aProgram
                                     withBuilder:(llvm::IRBuilder<> *)aBuilder
                                           value:(llvm::Value *)aValue;
@end

@interface TQNodeUnlessBlock : TQNodeIfBlock
+ (TQNodeUnlessBlock *)node;
@end

@interface TQNodeTernaryOperator : TQNodeIfBlock
@property(readwrite, retain) TQNode *ifExpr, *elseExpr;
+ (TQNodeTernaryOperator *)node;
+ (TQNodeTernaryOperator *)nodeWithIfExpr:(TQNode *)aIfExpr else:(TQNode *)aElseExpr;
@end
