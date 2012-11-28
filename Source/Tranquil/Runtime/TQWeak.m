#import "TQWeak.h"
#import "TQNil.h"

#if !__has_feature(objc_arc)
#error "TQWeak must be compiled with -fobjc-arc!"
#endif

extern BOOL TQObjectIsStackBlock(id aBlock); // We can't #import Runtime.h because it contains code not allowed under ARC

@interface TQWeak ()
@property(weak) id __obj;
@end

@implementation TQWeak
@synthesize __obj;
+ (id)with:(id)aObj
{
    TQWeak *ret = [self alloc];
    if(TQObjectIsStackBlock(aObj))
        aObj = [aObj copy];
    ret.__obj = aObj;
    return ret;
}
- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return __obj ?: TQGlobalNil;
}

- (NSString *)description    { return [__obj description]; }
- (Class)class               { return [__obj class];       }
- (NSUInteger)hash           { return [__obj hash];        }

- (BOOL)isEqual:(id)anObject {
    if(!__obj)
        return [TQGlobalNil isEqual:anObject];
    return [__obj isEqual:anObject];
}

- (id)self
{
    return __obj;
}

@end
