#import "TQRootObject.h"
#import <Foundation/NSException.h>

@implementation TQRootObject
+ (void)initialize
{
    // Required
}

+ (Class)class
{
    return self;
}
- (Class)class
{
    return object_getClass(self);
}

+ (Class)superclass
{
    return class_getSuperclass(self);
}
- (Class)superclass
{
    return class_getSuperclass([self class]);
}

+ (BOOL)isSubclassOfClass:(Class)cls
{
    for(Class tcls = self; tcls; tcls = class_getSuperclass(tcls)) {
        if (tcls == cls) return YES;
    }
    return NO;
}

+ (BOOL)isMemberOfClass:(Class)cls
{
    return object_getClass((id)self) == cls;
}

- (BOOL)isMemberOfClass:(Class)cls
{
    return [self class] == cls;
}

+ (BOOL)isKindOfClass:(Class)cls
{
    for(Class tcls = object_getClass((id)self); tcls; tcls = class_getSuperclass(tcls)) {
        if (tcls == cls) return YES;
    }
    return NO;
}
- (BOOL)isKindOfClass:(Class)cls
{
    for(Class tcls = [self class]; tcls; tcls = class_getSuperclass(tcls)) {
        if (tcls == cls) return YES;
    }
    return NO;
}

+ (NSString *)description
{
    return [NSString stringWithUTF8String:class_getName(self)];
}
- (NSString *)description
{
    return [NSString stringWithUTF8String:object_getClassName(self)];
}

+ (NSString *)_copyDescription
{
    return [[self description] copy];
}
- (NSString *)_copyDescription
{
    return [[self description] copy];
}

+ (NSString *)debugDescription
{
    return [self description];
}
- (NSString *)debugDescription
{
    return [self description];
}

+ (void)doesNotRecognizeSelector:(SEL)sel
{
    [NSException raise:NSInvalidArgumentException
                format:@"+[%s %s]: unrecognized selector sent to instance %p", 
                       class_getName(self), sel_getName(sel), self];
}
- (void)doesNotRecognizeSelector:(SEL)sel
{
    [NSException raise:NSInvalidArgumentException
                format:@"-[%s %s]: unrecognized selector sent to instance %p", 
                       object_getClassName(self), sel_getName(sel), self];
}

+ (BOOL)respondsToSelector:(SEL)sel
{
    return sel ? class_respondsToSelector(object_getClass((id)self), sel) : NO;
}
- (BOOL)respondsToSelector:(SEL)sel
{
    return sel ? class_respondsToSelector(object_getClass((id)self), sel) : NO;
}
@end
