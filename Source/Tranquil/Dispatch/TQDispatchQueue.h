#import <Tranquil/Runtime/TQObject.h>

@class TQNumber;

@interface TQDispatchQueue : TQObject {
    dispatch_queue_t _queue;
}
+ (TQDispatchQueue *)queueWithPriority:(TQNumber *)aPriority;

- (id)suspend;
- (id)resume;

- (id)dispatch:(dispatch_block_t)aBlock;
- (id)dispatch:(dispatch_block_t)aBlock asynchronously:(id)aIsAsync;
- (id)dispatch:(dispatch_block_t)aBlock afterDelay:(TQNumber *)aDelay;

@end

