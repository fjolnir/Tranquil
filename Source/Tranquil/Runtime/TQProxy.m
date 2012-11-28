#import "TQProxy.h"
#import <objc/runtime.h>
#import <Foundation/NSAutoreleasePool.h>
#import <stdlib.h>

@interface TQProxy () {
    Class isa;
    int32_t _retainCountMinusOne;
}
@end

@implementation TQProxy

+ (void)initialize
{
    // Required
}

+ (id)alloc
{
    return class_createInstance(self, 0);
}

- (void)dealloc
{
    free(self);
}

- (BOOL)isProxy
{
    return YES;
}

- (id)retain
{
    __sync_add_and_fetch(&_retainCountMinusOne, 1);
    return self;
}

- (void)release
{
    if(__sync_add_and_fetch(&_retainCountMinusOne, -1) == -1)
        [self dealloc];
}

- (id)autorelease
{
    [NSAutoreleasePool addObject:self];
    return self;
}

- (NSUInteger)retainCount
{
    return _retainCountMinusOne + 1;
}

@end

