#import "TQNode.h"

enum {
	kTQOperatorMultiply,
	kTQOperatorAdd,
	kTQOperatorSubtract,
	kTQOperatorDivide,
	kTQOperatorLesser,
	kTQOperatorAssign,
	kTQOperatorGreater,
	kTQOperatorLesserOrEqual,
	kTQOperatorGreaterOrEqual,
	kTQOperatorEqual,
	kTQOperatorInequal
};
typedef char TQOperatorType;
// Binary operator (a <operator> b)
@interface TQNodeBinaryOperator : TQNode
@property(readwrite, assign) TQOperatorType type;
@property(readwrite, retain) TQNode *left;
@property(readwrite, retain) TQNode *right;
+ (TQNodeBinaryOperator *)nodeWithType:(TQOperatorType)aType left:(TQNode *)aLeft right:(TQNode *)aRight;
- (id)initWithType:(TQOperatorType)aType left:(TQNode *)aLeft right:(TQNode *)aRight;
@end
