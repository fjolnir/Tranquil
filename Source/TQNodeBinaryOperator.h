#import "TQNode.h"

enum {
	kTQOperatorAssign = '=',
	kTQOperatorPlus = '+',
	kTQOperatorMinus = '-',
	kTQOperatorMultiply = '*',
	kTQOperatorDivide = '/',
	kTQOperatorGreater = '>',
	kTQOperatorLesser = '<'
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
