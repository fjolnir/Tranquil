#import "TQMemoryManagementProcessor.h"
#import "../TQNodeMessage.h"
#import "../TQNodeArgument.h"

@implementation TQMemoryManagementProcessor
+ (void)load
{
    if(self != [TQMemoryManagementProcessor  class])
        return;
    [TQProcessor registerProcessor:self];
}

+ (TQNode *)processNode:(TQNode *)aNode withTrace:(NSArray *)aTrace
{
    if(![aNode isKindOfClass:[TQNodeMessage class]])
        return aNode;
    TQNodeMessage *msg  = (TQNodeMessage *)aNode;
    TQNodeMessage *rcvr = (TQNodeMessage *)msg.receiver;
    NSString *sel = [msg selector];
    if([sel isEqualToString:@"new"]   ||
       [sel hasPrefix:@"copy"]        ||
       [sel hasPrefix:@"mutableCopy"] ||
       ([rcvr isKindOfClass:[TQNodeMessage class]] && [rcvr.selector hasPrefix:@"alloc"]))
    {
        msg.needsAutorelease = YES;
        return msg;
    }
    return aNode;
}
@end
