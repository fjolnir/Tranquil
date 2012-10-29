#import <Tranquil/CodeGen/TQNode.h>

enum {
    kTQOperatorMultiply,
    kTQOperatorAdd,
    kTQOperatorSubtract,
    kTQOperatorDivide,
    kTQOperatorModulo,
    kTQOperatorLesser,
    kTQOperatorAssign,
    kTQOperatorAnd,
    kTQOperatorOr,
    kTQOperatorGreater,
    kTQOperatorLesserOrEqual,
    kTQOperatorGreaterOrEqual,
    kTQOperatorEqual,
    kTQOperatorInequal,
    kTQOperatorUnaryMinus,
    kTQOperatorSubscript,
    kTQOperatorIncrement,
    kTQOperatorDecrement,
    kTQOperatorLShift,
    kTQOperatorRShift,
    kTQOperatorConcat,
    kTQOperatorExponent
};
typedef char TQOperatorType;
// Binary operator (a <operator> b)
@interface TQNodeOperator : TQNode
@property(readwrite) TQOperatorType type;
@property(readwrite, retain) id left;
@property(readwrite, retain) id right;

+ (TQNodeOperator *)nodeWithType:(TQOperatorType)aType left:(TQNode *)aLeft right:(TQNode *)aRight;
- (id)initWithType:(TQOperatorType)aType left:(TQNode *)aLeft right:(TQNode *)aRight;
@end

@interface TQNodeAssignOperator : TQNodeOperator
@property(readwrite) TQOperatorType type;
@property(readwrite, retain) NSMutableArray *left;
@property(readwrite, retain) NSMutableArray *right;
+ (TQNodeAssignOperator *)nodeWithType:(int)aType left:(NSMutableArray *)aLeft right:(NSMutableArray *)aRight;
@end
