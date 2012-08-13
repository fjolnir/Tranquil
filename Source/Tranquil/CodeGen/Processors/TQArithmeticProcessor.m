#import "TQArithmeticProcessor.h"
#import "../TQNodeOperator.h"
#import "../TQNodeNumber.h"
#import "../TQNodeValid.h"
#import "../TQNodeNil.h"

@implementation TQArithmeticProcessor
+ (void)load
{
    if(self != [TQArithmeticProcessor class])
        return;
    [TQProcessor registerProcessor:self];
}

+ (TQNode *)processNode:(TQNode *)aNode withTrace:(NSArray *)aTrace
{
    if(![aNode isKindOfClass:[TQNodeOperator class]])
        return aNode;

    TQNodeOperator *op = (TQNodeOperator *)aNode;

    NSMutableArray *subTrace = [aTrace mutableCopy];
    [subTrace addObject:op];
    if([op.left isKindOfClass:[TQNodeOperator class]])
        [self processNode:op.left withTrace:subTrace];
    if([op.right isKindOfClass:[TQNodeOperator class]])
        [self processNode:op.right withTrace:subTrace];
    [subTrace release];

    if(![op.left isKindOfClass:[TQNodeNumber class]] || ![op.right isKindOfClass:[TQNodeNumber class]])
        return aNode;

    TQNode *replacement;
    double left  = ((TQNodeNumber *)op.left).value.doubleValue;
    double right = ((TQNodeNumber *)op.right).value.doubleValue;
    switch(op.type) {
        case kTQOperatorMultiply:
            replacement = [TQNodeNumber nodeWithDouble:left * right];
            break;
        case kTQOperatorAdd:
            replacement = [TQNodeNumber nodeWithDouble:left + right];
            break;
        case kTQOperatorSubtract:
            replacement = [TQNodeNumber nodeWithDouble:left - right];
            break;
        case kTQOperatorDivide:
            replacement = [TQNodeNumber nodeWithDouble:left / right];
            break;
        case kTQOperatorModulo:
            replacement = [TQNodeNumber nodeWithDouble:fmod(left, right)];
            break;
        case kTQOperatorGreater:
            replacement = left > right ? [TQNodeValid node] : [TQNodeNil node];
            break;
        case kTQOperatorLesser:
            replacement = left < right ? [TQNodeValid node] : [TQNodeNil node];
            break;
        case kTQOperatorLesserOrEqual:
            replacement = left <= right ? [TQNodeValid node] : [TQNodeNil node];
            break;
        case kTQOperatorGreaterOrEqual:
            replacement = left >= right ? [TQNodeValid node] : [TQNodeNil node];
            break;
        case kTQOperatorEqual:
            replacement = left == right ? [TQNodeValid node] : [TQNodeNil node];
            break;
        case kTQOperatorInequal:
            replacement = left != right ? [TQNodeValid node] : [TQNodeNil node];
            break;
        case kTQOperatorUnaryMinus:
            replacement = [TQNodeNumber nodeWithDouble:-right];
            break;
        case kTQOperatorLShift:
            replacement = [TQNodeNumber nodeWithDouble:(long)left << (long)right];
            break;
        case kTQOperatorRShift:
            replacement = [TQNodeNumber nodeWithDouble:(long)left >> (long)right];
            break;
        case kTQOperatorExponent:
            replacement = [TQNodeNumber nodeWithDouble:powf(left, right)];
            break;
        default:
            return aNode;
    }
    [[aTrace lastObject] replaceChildNodesIdenticalTo:aNode with:replacement];

    return aNode;
}
@end
