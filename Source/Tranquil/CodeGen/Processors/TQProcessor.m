#import "TQProcessor.h"

static OFMutableArray *_Processors;

@implementation TQProcessor
+ (OFArray *)allProcessors
{
    return _Processors;
}

+ (void)registerProcessor:(TQProcessor *)aProcessor
{
    if(!_Processors)
        _Processors = [OFMutableArray new];
    [_Processors addObject:aProcessor];
}

+ (TQNode *)processNode:(TQNode *)aNode withTrace:(OFArray *)aTrace
{
    return aNode;
}

+ (BOOL)canProcessNode:(TQNode *)aNode
{
    return NO;
}
@end
