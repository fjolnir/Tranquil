#import "TQDeallocInsertProcessor.h"
#import "../TQNodeMethod.h"
#import "../TQNodeMessage.h"
#import "../TQNodeVariable.h"
#import "../TQNodeArgument.h"

@implementation TQDeallocInsertProcessor
+ (void)load
{
    if(self != [TQDeallocInsertProcessor class])
        return;
    [TQProcessor registerProcessor:self];
}

+ (TQNode *)processNode:(TQNode *)aNode withTrace:(OFArray *)aTrace
{
    if(![aNode isKindOfClass:[TQNodeMethod class]])
        return aNode;
    TQNodeMethod *method = (TQNodeMethod *)aNode;

    if(method.type == kTQInstanceMethod && [[method selector] isEqual:@"dealloc"]) {
        TQNodeMessage *superDealloc = [TQNodeMessage nodeWithReceiver:[TQNodeSuper node]];
        [superDealloc.arguments addObject:[TQNodeArgument nodeWithPassedNode:nil selectorPart:@"dealloc"]];
        if(![method referencesNode:superDealloc])
            [method.statements addObject:superDealloc];
    }

    return aNode;
}
@end
