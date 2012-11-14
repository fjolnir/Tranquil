#import "TQRuntime.h"

@interface OFObject (Tranquil)
+ (id)include:(Class)aClass;
- (OFString *)toString;
- (id)print;
@end

#ifdef __APPLE__
@interface NSObject (Tranquil)
+ (id)include:(Class)aClass;
@end
#endif
