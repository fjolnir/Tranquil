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
        aObj = [aObj copy]; // Leaks :/
    ret.__obj = aObj;
    return ret;
}
- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return __obj ?: TQGlobalNil;
}

@end
