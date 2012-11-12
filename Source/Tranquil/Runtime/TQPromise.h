#import <ObjFW/ObjFW.h>

@interface TQPromise : OFObject
- (id)fulfilled;
- (void)fulfillWith:(id)aResult;
// Blocks the current thread until the promise is fulfilled & then returns the result
- (id)waitTillFulfilled;
@end

