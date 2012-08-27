#import "TQAsyncProcessor.h"
#import "../TQNodeWeak.h"
#import "../TQNodeBlock.h"
#import "../TQNodeMethod.h"
#import "../TQNodeOperator.h"
#import "../TQNodeVariable.h"
#import "../TQNodeAsync.h"

@implementation TQAsyncProcessor
+ (void)load
{
    if(self != [TQAsyncProcessor class])
        return;
    [TQProcessor registerProcessor:self];
}

+ (TQNode *)processNode:(TQNode *)aNode withTrace:(NSArray *)aTrace
{
    if(![aNode isKindOfClass:[TQNodeAsync class]])
        return aNode;
    TQNodeAsync *async = (TQNodeAsync *)aNode;

    if([async.expression isKindOfClass:[TQNodeOperator class]]
            && [(TQNodeOperator *)async.expression type] == kTQOperatorAssign
            && [[(TQNodeOperator *)async.expression left] isKindOfClass:[TQNodeVariable class]]) {
        TQAssert([[aTrace lastObject] isKindOfClass:[TQNodeBlock class]], @"Invalid syntax tree! Async statements must be children of a block");
        [[aTrace lastObject] insertChildNode:[(TQNodeOperator *)async.expression left] before:async];
    }
    return aNode;
}
@end
