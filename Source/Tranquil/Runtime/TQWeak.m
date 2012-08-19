#import "TQWeak.h"

#if !__has_feature(objc_arc)
#error "TQWeak must be compiled with -fobjc-arc!"
#endif

extern BOOL TQObjectIsStackBlock(id aBlock); // We can't #import Runtime.h because it contains code not allowed under ARC<D-k>

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

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    [anInvocation setTarget:__obj];
    [anInvocation invoke];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    static NSMethodSignature *nilRetSignature;
    if(!__obj) {
        if(!nilRetSignature) {
            @synchronized(self) {
                nilRetSignature = [NSMethodSignature signatureWithObjCTypes:"@:"];
            }
        }
        return nilRetSignature;
    }
    return [__obj methodSignatureForSelector:aSelector];
}

- (NSString *)description    { return [__obj description];      }
- (Class)class               { return [__obj class];            }
- (NSUInteger)hash           { return [__obj hash];             }
- (BOOL)isEqual:(id)anObject { return [__obj isEqual:anObject]; }
@end
