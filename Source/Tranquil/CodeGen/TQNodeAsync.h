#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeAsync : TQNode
@property(readwrite, retain) TQNode *expression;

+ (TQNodeAsync *)nodeWithExpression:(TQNode *)aExpression;
@end

@interface TQNodeWait : TQNode
+ (TQNodeWait *)node;
@end

@interface TQNodeWhenFinished : TQNodeAsync
+ (TQNodeWhenFinished *)nodeWithExpression:(TQNode *)aExpression;
@end
