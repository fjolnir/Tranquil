#import "TQNodeBlock.h"
#include <llvm/Support/IRBuilder.h>

@interface TQNodeIfBlock : TQNode {
    @protected
     OFMutableArray *_ifStatements, *_elseStatements;
}
@property(readwrite, retain) TQNode *condition;
@property(readwrite, copy) OFMutableArray *ifStatements, *elseStatements;

+ (TQNodeIfBlock *)node;
+ (TQNodeIfBlock *)nodeWithCondition:(TQNode *)aCond
                        ifStatements:(OFMutableArray *)ifStmt
                      elseStatements:(OFMutableArray *)elseStmt;
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
+ (TQNodeTernaryOperator *)nodeWithCondition:(TQNode *)aCond ifExpr:(TQNode *)aIfExpr else:(TQNode *)aElseExpr;
@end
