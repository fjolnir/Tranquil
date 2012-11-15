#import "NSObject+TQAdditions.h"
#import "TQNumber.h"
#import "TQRuntime.h"
#import "TQModule.h"
#import <objc/runtime.h>

@implementation NSObject (Tranquil)
- (NSMutableString *)toString
{
    return [[[self description] mutableCopy] autorelease];
}

- (id)print
{
NSLog(@"%@ printing %@ %p", self, [self class], self);
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

- (id)isIdenticalTo:(id)obj
{
    return self == obj ? TQValid : nil;
}

#define CopyMethods(kls, dst) do { \
    unsigned methodCount = 0; \
    Method *methods = class_copyMethodList(kls, &methodCount); \
    for(int i = 0; i < methodCount; ++i) { \
        class_addMethod(dst, method_getName(methods[i]), method_getImplementation(methods[i]), method_getTypeEncoding(methods[i])); \
    } \
    free(methods); \
} while(0);

+ (id)include:(Class)aClass recursive:(id)aRecursive
{
    TQAssert(aClass, @"Tried to include nil class");

    if([aClass isKindOfClass:[TQModule class]])
        TQAssert([aClass canBeIncludedInto:self],
                 @"%@ cannot be included into %@", aClass, self);

    do {
        CopyMethods(object_getClass(aClass), object_getClass(self));
        CopyMethods(aClass, self);
    } while(aRecursive && (aClass = class_getSuperclass(aClass)));
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
