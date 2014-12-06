#import "TQNodeBlock.h"
#include <llvm/IR/IRBuilder.h>

@interface TQNodeIfBlock : TQNode {
    @protected
     NSMutableArray *_ifStatements, *_elseStatements;
}
@property(readwrite, retain) TQNode *condition;
@property(readwrite, copy) NSMutableArray *ifStatements, *elseStatements;

+ (TQNodeIfBlock *)node;
+ (TQNodeIfBlock *)nodeWithCondition:(TQNode *)aCond
                        ifStatements:(NSMutableArray *)ifStmt
                      elseStatements:(NSMutableArray *)elseStmt;
- (llvm::Value *)generateTestExpressionInProgram:(TQProgram *)aProgram
                                     withBuilder:(llvm::IRBuilder<> *)aBuilder
                                           value:(llvm::Value *)aValue;
@end

@interface TQNodeUnlessBlock : TQNodeIfBlock
+ (TQNodeUnlessBlock *)nodeWithCondition:(TQNode *)aCond
                            ifStatements:(NSMutableArray *)ifStmt
                          elseStatements:(NSMutableArray *)elseStmt;
+ (TQNodeUnlessBlock *)node;
@end

@interface TQNodeTernaryOperator : TQNodeIfBlock
@property(readwrite, retain) TQNode *ifExpr, *elseExpr;
@property(readwrite, assign) BOOL isNegated;
+ (TQNodeTernaryOperator *)node;
+ (TQNodeTernaryOperator *)nodeWithCondition:(TQNode *)aCond ifExpr:(TQNode *)aIfExpr else:(TQNode *)aElseExpr;
@end
