#import "TQNothingness.h"
#import <objc/runtime.h>
#import "TQRuntime.h"

static TQNothingness *sharedInstance;

@implementation TQNothingness
+ (void)load
{
    if(self != [TQNothingness class])
        return;
    sharedInstance = class_createInstance(self, 0);
}

+ (id)nothing
{
    return sharedInstance;
}

+ (id)include:(Class)aClass recursive:(id)aRecursive
{
    TQAssert(NO, @"Extending nothing is not allowed");
    return nil;
}

+ (id)alloc
{
    TQAssert(NO, @"You're trying to create nothing. You make no sense.");
    return nil;
}

- (id)copy
{
    TQAssert(NO, @"You're trying to copy nothing. You make no sense.");
    return nil;
}

- (void)release {}
- (id)retain
{
    return self;
}

- (BOOL)respondsToSelector:(SEL)selector
{
    return NO;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return NO;
}

- (uint32_t)hash
{
    return 0;
}

- (BOOL)isEqual:(id)obj
{
    return obj == self; // There's only one instance
}

- (OFString *)description
{
    return @"(nothing)";
}

- (Class)class
{
    return nil;
}
@end

