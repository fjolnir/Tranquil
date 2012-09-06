#import "NSObject+TQAdditions.h"
#import "TQNumber.h"
#import "TQRuntime.h"
#import <objc/runtime.h>

@implementation NSObject (Tranquil)
- (NSMutableString *)toString
{
    return [[[self description] mutableCopy] autorelease];
}

- (id)print
{
    printf("%s\n", [[self toString] UTF8String]);
    return self;
}
- (id)printWithoutNl
{
    printf("%s", [[self toString] UTF8String]);
    return self;
}

- (id)isa:(Class)aClass
{
    return [self isKindOfClass:aClass] ? TQValid : nil;
}

#define CopyMethods(kls, dst) do { \
    unsigned methodCount = 0; \
    Method *methods = class_copyMethodList(kls, &methodCount); \
    for(int i = 0; i < methodCount; ++i) { \
        class_addMethod(dst, method_getName(methods[i]), method_getImplementation(methods[i]), method_getTypeEncoding(methods[i])); \
    } \
    free(methods); \
} while(0);

+ (id)include:(Class)aClass recursive:(TQNumber *)aRecursive
{
    if([aClass isKindOfClass:[NSString class]])
        aClass = NSClassFromString((NSString *)aClass);
    TQAssert(aClass, @"Tried to include nil class");

    do {
        CopyMethods(object_getClass(aClass), object_getClass(self));
        CopyMethods(aClass, self);
    } while([aRecursive boolValue] && (aClass = class_getSuperclass(aClass)));
    return TQValid;
}
#undef CopyMethods
+ (id)include:(Class)aClass
{
    return [self include:aClass recursive:nil];
}

- (id)isNil
{
    return nil;
}
@end
