#import "TQObject.h"
#import "TQNumber.h"
#import "TQRuntime.h"
#import "NSString+TQAdditions.h"
#import <objc/runtime.h>

static NSArray *methodsForClass(Class kls);

@implementation TQObject
+ (id)addMethod:(NSString *)aSel withBlock:(id)aBlock replaceExisting:(id)shouldReplace
{
    if(!aBlock) {
        TQLog(@"Tried to add nil block as method (%@)", aSel);
        return nil;
    }
    IMP imp = imp_implementationWithBlock(aBlock);
    NSMutableString *type = [NSMutableString stringWithString:@"@:"];
    const char *selCStr = [aSel UTF8String];
    for(int i = 0; i < [aSel length]; ++i) {
        if(selCStr[i] == ':')
            [type appendString:@"@"];
    }
    if(shouldReplace)
        class_replaceMethod(self, NSSelectorFromString(aSel), imp, [type UTF8String]);
    else
        class_addMethod(self, NSSelectorFromString(aSel), imp, [type UTF8String]);
    return TQValid;
}

+ (id)addMethod:(NSString *)aSel withBlock:(id)aBlock
{
    return [self addMethod:aSel withBlock:aBlock replaceExisting:TQValid];
}

+ (NSArray *)classMethods
{
    return methodsForClass(object_getClass(self));
}
+ (NSArray *)instanceMethods
{
    return methodsForClass(self);
}
- (NSArray *)methods
{
    return [[self class] instanceMethods];
}

+ (id)accessor:(NSString *)aPropName initialValue:(id<NSCopying>)aInitial
{
    [self addMethod:aPropName withBlock:^(id self_) {
        __block id ret = [TQGetDynamicIvarTable(self_) objectForKey:aPropName];
        if(!ret && aInitial) {
            @synchronized(self_) {
                ret = [aInitial copyWithZone:nil];
                [TQGetDynamicIvarTable(self_) setObject:ret forKey:aPropName];
                [ret release];
            }
        }
        return ret;
    } replaceExisting:nil];
    NSString *setterSel = [NSString stringWithFormat:@"set%@:", [aPropName stringByCapitalizingFirstLetter]];
    [self addMethod:setterSel withBlock:^(id self_, id val) {
        NSMutableDictionary *ivars = TQGetDynamicIvarTable(self_);
        if(val)
            [ivars setObject:val forKey:aPropName];
        else
            [ivars removeObjectForKey:aPropName];
        return nil;
    }
                        replaceExisting:nil];

    return TQValid;
}

+ (id)accessor:(NSString *)aPropName
{
    return [self accessor:aPropName initialValue:nil];
}

+ (id)accessors:(NSArray *)aAccessors initialValue:(id<NSCopying>)aInitial
{
    for(NSString *name in aAccessors) {
        [self accessor:name initialValue:aInitial];
    }
    return nil;
}
+ (id)accessors:(NSArray *)aAccessors
{
    return [self accessors:aAccessors initialValue:nil];
}

- (id)isa:(Class)aClass
{
    return [self isKindOfClass:aClass] ? TQValid : nil;
}

- (id)respondsTo:(NSString *)aSelector
{
    return [self respondsToSelector:NSSelectorFromString(aSelector)] ? TQValid : nil;
}

- (NSMutableString *)toString
{
    return [[[self description] mutableCopy] autorelease];
}

- (id)print
{
    printf("%s\n", [[self toString] UTF8String]);
    return nil;
}
- (id)printWithoutNl
{
    printf("%s", [[self toString] UTF8String]);
    return self;
}

- (id)isNil
{
    return nil;
}

- (id)isIdenticalTo:(id)obj
{
    return self == obj ? TQValid : nil;
}
- (id)isEqualTo:(id)b
{
    return [self isEqual:b] ? TQValid : nil;
}
- (id)notEqualTo:(id)b
{
    return [self isEqual:b] ? nil : TQValid;
}
- (id)isLesserThan:(id)b
{
    return ([(id)self compare:b] == NSOrderedAscending) ? TQValid : nil;
}
- (id)isGreaterThan:(id)b
{
    return ([(id)self compare:b] == NSOrderedDescending) ? TQValid : nil;
}
- (id)isLesserOrEqualTo:(id)b
{
    return ([(id)self compare:b] != NSOrderedDescending) ? TQValid : nil;
}
- (id)isGreaterOrEqualTo:(id)b
{
    return ([(id)self compare:b] != NSOrderedAscending) ? TQValid : nil;
}
@end

static NSArray *methodsForClass(Class kls)
{
    unsigned int count;
    Method *methods = class_copyMethodList(kls, &count);
    NSMutableArray *methodArray = [NSMutableArray arrayWithCapacity:count];
    for(int i = 0; i < count; ++i) {
        SEL selector = method_getName(methods[i]);
        [methodArray addObject:[NSString stringWithUTF8String:sel_getName(selector)]];
    }
    free(methods);
    return methodArray;
}
