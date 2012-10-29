#import <Foundation/Foundation.h>

@interface TQPromise : NSProxy
- (id)fulfilled;
- (void)fulfillWith:(id)aResult;
// Blocks the current thread until the promise is fulfilled & then returns the result
- (id)waitTillFulfilled;
@end

