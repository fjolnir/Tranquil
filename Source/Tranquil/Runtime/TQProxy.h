#include <Foundation/NSObjCRuntime.h>

// Because NSProxy does too much.
@interface TQProxy
+ (id)alloc;

- (void)dealloc;
- (BOOL)isProxy;
- (id)retain;
- (void)release;
- (id)autorelease;
- (NSUInteger)retainCount;
@end
