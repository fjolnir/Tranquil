#import "OFObject+TQAdditions.h"
#import "TQRuntime.h"
#import "TQModule.h"
#import <objc/runtime.h>

//@interface TQRootObjectAdditions : TQModule
//- (id)toString;
//- (id)print;
//- (id)printWithoutNl;
//- (id)isa:(Class)aClass;
//- (id)isIdenticalTo:(id)obj;
//- (id)isNil;
//@end
//@implementation TQRootObjectAdditions
#define CAT \
- (id)toString \
{ \
    return [[[self description] mutableCopy] autorelease]; \
} \
 \
- (id)print \
{ \
    printf("%s\n", [[self toString] UTF8String]); \
    return self; \
} \
- (id)printWithoutNl \
{ \
    printf("%s", [[self toString] UTF8String]); \
    return self; \
} \
 \
- (id)isa:(Class)aClass \
{ \
    return [self isKindOfClass:aClass] ? TQValid : nil; \
} \
 \
- (id)isIdenticalTo:(id)obj \
{ \
    return self == obj ? TQValid : nil; \
} \
 \
- (id)isNil \
{ \
    return nil; \
}

@implementation OFObject (Tranquil)
+ (id)include:(Class)aClass
{
    [self inheritMethodsFromClass:aClass];
    return TQValid;
}

- (id)methodSignatureForSelector:(SEL)aSelector
{
    TQAssert(NO, @"Unsupported selector %s sent to %@", sel_getName(aSelector), [self class]);
    return nil;
}
CAT
@end

#ifdef __APPLE__
@implementation NSObject (Tranquil)
#define CopyMethods(kls, dst) do { \
    unsigned methodCount = 0; \
    Method *methods = class_copyMethodList(kls, &methodCount); \
    for(int i = 0; i < methodCount; ++i) { \
        class_addMethod(dst, method_getName(methods[i]), method_getImplementation(methods[i]), method_getTypeEncoding(methods[i])); \
    } \
    free(methods); \
} while(0);
+ (id)include:(Class)aClass
{
    TQAssert(aClass, @"Tried to include nil class");

    if([aClass isKindOfClass:[TQModule class]])
        TQAssert([aClass canBeIncludedInto:self],
                 @"%@ cannot be included into %@", aClass, self);

    do {
        CopyMethods(object_getClass(aClass), object_getClass(self));
        CopyMethods(aClass, self);
    } while((aClass = class_getSuperclass(aClass)));

    return TQValid;
}
#undef CopyMethods
CAT
@end
#endif
