#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeAsync : TQNode
@property(readwrite, retain) TQNode *expression;

+ (TQNodeAsync *)nodeWithExpression:(TQNode *)aExpression;
@end

@interface TQNodeWait : TQNode
@property(readwrite, retain) TQNode *timeoutExpr;
+ (TQNodeWait *)node;
@end

@interface TQNodeWhenFinished : TQNodeAsync
+ (TQNodeWhenFinished *)nodeWithExpression:(TQNode *)aExpression;
@end
