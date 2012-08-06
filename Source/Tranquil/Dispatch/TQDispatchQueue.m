#import "TQDispatchQueue.h"
#import "../Runtime/TQNumber.h"

@implementation TQDispatchQueue
+ (TQDispatchQueue *)queue
{
    return [self queueWithPriority:(TQNumber*)@0];
}

+ (TQDispatchQueue *)queueWithPriority:(TQNumber *)aPriority
{
    return [[[self alloc] initWithPriority:aPriority] autorelease];
}

- (id)initWithPriority:(TQNumber *)aPriority
{
    if(!(self = [super init]))
        return nil;
    _queue = dispatch_get_global_queue([aPriority longValue], 0);

    return self;
}

- (id)init
{
    return [self initWithPriority:(TQNumber*)@0];
}


- (id)suspend
{
    dispatch_suspend(_queue);
    return nil;
}

- (id)resume
{
    dispatch_resume(_queue);
    return nil;
}

- (id)dispatch:(dispatch_block_t)aBlock
{
    return [self dispatch:aBlock asynchronously:(TQNumber*)@YES];
}

- (id)dispatch:(dispatch_block_t)aBlock asynchronously:(TQNumber *)aIsAsync
{
    if([aIsAsync boolValue])
        dispatch_async(_queue, aBlock);
    else
        dispatch_sync(_queue, aBlock);
    return nil;
}

- (id)dispatch:(dispatch_block_t)aBlock afterDelay:(TQNumber *)aDelay
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([aDelay doubleValue] * NSEC_PER_SEC)), _queue, aBlock);
    return nil;
}
@end
