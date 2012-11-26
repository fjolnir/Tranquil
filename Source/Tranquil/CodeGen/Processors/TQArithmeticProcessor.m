#import "TQArithmeticProcessor.h"
#import "../TQNodeOperator.h"
#import "../TQNodeNumber.h"
#import "../TQNodeValid.h"
#import "../TQNodeCustom.h"
#import "../TQNodeNil.h"
#import <objc/runtime.h>

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

    if(![op.left isKindOfClass:[TQNodeNumber class]]) {
        if(op.type != kTQOperatorExponent || ![op.right isKindOfClass:[TQNodeNumber class]])
            return aNode;
        // Check if we have an integer exponent, if so we can expand it to a multiplication/division
        double expf = [[(TQNodeNumber *)op.right value] doubleValue];
        if(round(expf) != expf || expf > 6)
            return aNode;
        if(exp == 0)
            return [TQNodeNumber nodeWithDouble:1];
        long exp = (long)expf;
        BOOL isNeg = exp < 0;
        exp = abs(exp);

        TQNode *left = op.left;
        TQNodeCustom *num = [TQNodeCustom nodeWithBlock:^(TQProgram *p, TQNodeBlock *b, TQNodeRootBlock *r) {
            // little bit of a hack to make sure we only evaluate the left side once
            NSValue *val = objc_getAssociatedObject(left, @"ExponentExpansionTemp");
            if(!val) {
                val = [NSValue valueWithPointer:[left generateCodeInProgram:p block:b root:r error:nil]];
                objc_setAssociatedObject(op.left, @"ExponentExpansionTemp", val, OBJC_ASSOCIATION_RETAIN);
            }
            return (llvm::Value *)[val pointerValue];
        }];
        TQNode *replacement = num;
        for(int i = 1; i < exp; ++i) {
            replacement = [TQNodeOperator nodeWithType:kTQOperatorMultiply left:replacement right:num];
        }
        if(isNeg)
            replacement = [TQNodeOperator nodeWithType:kTQOperatorDivide left:[TQNodeNumber nodeWithDouble:1] right:replacement];
        [[aTrace lastObject] replaceChildNodesIdenticalTo:aNode with:replacement];

        return replacement;
    } else if(![op.right isKindOfClass:[TQNodeNumber class]])
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
