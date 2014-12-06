#import "TQProcessor.h"

static NSMutableArray *_Processors;

@implementation TQProcessor
+ (NSArray *)allProcessors
{
    return _Processors;
}

+ (void)registerProcessor:(TQProcessor *)aProcessor
{
    if(!_Processors)
        _Processors = [NSMutableArray new];
    [_Processors addObject:aProcessor];
}

+ (TQNode *)processNode:(TQNode *)aNode withTrace:(NSArray *)aTrace
{
    return aNode;
}

+ (BOOL)canProcessNode:(TQNode *)aNode
{
    return NO;
}
@end
