#import "TQObject.h"
#import "TQNumber.h"
#import "TQEnumerable.h"
#import "TQRuntime.h"
#import "NSString+TQAdditions.h"
#import "NSCollections+Tranquil.h"
#import "../../../Build/TQStubs.h"
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

+ (id)initializer:(NSArray *)aProperties
{
    TQAssert([aProperties count] > 0, @"No properties to initialize passed");
    NSMutableString *sel = [NSMutableString stringWithString:@"with"];
    [sel appendFormat:@"%@:", [aProperties[0] stringByCapitalizingFirstLetter]];
    for(int i = 1; i < [aProperties count]; ++i) {
        [sel appendFormat:@"%@:", aProperties[i]];
    }
    [[self metaClass] addMethod:sel withBlock:^(id self, ...) {
        id instance = [self new];
        va_list params;
        va_start(params, self);
        for(NSString *prop in aProperties) {
            TQSetValueForKey(instance, prop, va_arg(params, id));
        }
        va_end(params);
        return [instance autorelease];
    }];
    return nil;
}

+ (id)reader:(NSString *)aPropName initialValue:(id<NSCopying>)aInitial
{
    return [self addMethod:aPropName withBlock:^(id self_) {
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
}

+ (id)reader:(NSString *)aPropName
{
    return [self reader:aPropName initialValue:nil];
}

+ (id)readers:(id)aAccessors
{
    if([aAccessors isa:[NSMapTable class]] || [aAccessors isa:[NSDictionary class]]) {
        for(NSString *name in aAccessors) {
            [self reader:name initialValue:[aAccessors objectForKey:name]];
        }
    } else {
        for(NSString *name in aAccessors) {
            [self reader:name initialValue:nil];
        }
    }
    return nil;
}

+ (id)accessor:(NSString *)aPropName initialValue:(id<NSCopying>)aInitial
{
    [self reader:aPropName initialValue:aInitial];

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

+ (id)accessors:(id)aAccessors
{
    if([aAccessors isa:[NSMapTable class]] || [aAccessors isa:[NSDictionary class]]) {
        for(NSString *name in aAccessors) {
            [self accessor:name initialValue:[aAccessors objectForKey:name]];
        }
    } else {
        for(NSString *name in aAccessors) {
            [self accessor:name initialValue:nil];
        }
    }
    return nil;
}

+ (id)isEqualTo:(id)b
{
    return [self isEqual:b] ? TQValid : nil;
}
+ (id)notEqualTo:(id)b
{
    return [self isEqual:b] ? nil : TQValid;
}

- (id)isa:(Class)aClass
{
    return [self isKindOfClass:aClass] ? TQValid : nil;
}

- (id)respondsTo:(NSString *)aSelector
{
    return [self respondsToSelector:NSSelectorFromString(aSelector)] ? TQValid : nil;
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

- (id)case:(id)aCases default:(id (^)())aDefaultCase
{
    id (^choice)() = [[aCases find:^(TQPair *pair) { return [self isEqualTo:[pair left]]; }] right];
    if(!choice)
        choice = aDefaultCase;
    return TQDispatchBlock0(choice);
}
- (id)case:(id)aCases
{
    return [self case:aCases default:nil];
}

#pragma mark - Dynamic message dispatchers

- (id)perform:(NSString *)aSelector withArguments:(NSArray *)aArguments
{
    NSUInteger count = [aArguments count];
    SEL sel = NSSelectorFromString(aSelector);
#define A(n) [aArguments objectAtIndex:(n)]
    switch(count) {
        case 0: return tq_msgSend(self, sel);
        case 1: return tq_msgSend(self, sel, A(0));
        case 2: return tq_msgSend(self, sel, A(0), A(1));
        case 3: return tq_msgSend(self, sel, A(0), A(1), A(2));
        case 4: return tq_msgSend(self, sel, A(0), A(1), A(2), A(3));
        case 5: return tq_msgSend(self, sel, A(0), A(1), A(2), A(3), A(4));
        case 6: return tq_msgSend(self, sel, A(0), A(1), A(2), A(3), A(4), A(5));
        case 7: return tq_msgSend(self, sel, A(0), A(1), A(2), A(3), A(4), A(5), A(6));
        case 8: return tq_msgSend(self, sel, A(0), A(1), A(2), A(3), A(4), A(5), A(6), A(7));
        case 9: return tq_msgSend(self, sel, A(0), A(1), A(2), A(3), A(4), A(5), A(6), A(7), A(8));
        default:
            [NSException raise:NSInternalInconsistencyException
                        format:@"Dynamic message dispatch attempted with %ld arguments (9 supported)", (long)count];
    }
#undef A
    return nil;
}

- (id)perform:(NSString *)aSelector
{
    return tq_msgSend(self, NSSelectorFromString(aSelector));
}
- (id)perform:(NSString *)aSelector :(id)a1
{
    return tq_msgSend(self, NSSelectorFromString(aSelector), a1);
}
- (id)perform:(NSString *)aSelector :(id)a1 :(id)a2
{
    return tq_msgSend(self, NSSelectorFromString(aSelector), a1, a2);
}
- (id)perform:(NSString *)aSelector :(id)a1 :(id)a2 :(id)a3
{
    return tq_msgSend(self, NSSelectorFromString(aSelector), a1, a2, a3);
}
- (id)perform:(NSString *)aSelector :(id)a1 :(id)a2 :(id)a3 :(id)a4
{
    return tq_msgSend(self, NSSelectorFromString(aSelector), a1, a2, a3, a4);
}
- (id)perform:(NSString *)aSelector :(id)a1 :(id)a2 :(id)a3 :(id)a4 :(id)a5
{
    return tq_msgSend(self, NSSelectorFromString(aSelector), a1, a2, a3, a4, a5);
}
- (id)perform:(NSString *)aSelector :(id)a1 :(id)a2 :(id)a3 :(id)a4 :(id)a5 :(id)a6
{
    return tq_msgSend(self, NSSelectorFromString(aSelector), a1, a2, a3, a4, a5, a6);
}
- (id)perform:(NSString *)aSelector :(id)a1 :(id)a2 :(id)a3 :(id)a4 :(id)a5 :(id)a6 :(id)a7
{
    return tq_msgSend(self, NSSelectorFromString(aSelector), a1, a2, a3, a4, a5, a6, a7);
}
- (id)perform:(NSString *)aSelector :(id)a1 :(id)a2 :(id)a3 :(id)a4 :(id)a5 :(id)a6 :(id)a7 :(id)a8
{
    return tq_msgSend(self, NSSelectorFromString(aSelector), a1, a2, a3, a4, a5, a6, a7, a8);
}
- (id)perform:(NSString *)aSelector :(id)a1 :(id)a2 :(id)a3 :(id)a4 :(id)a5 :(id)a6 :(id)a7 :(id)a8 :(id)a9
{
    return tq_msgSend(self, NSSelectorFromString(aSelector), a1, a2, a3, a4, a5, a6, a7, a8, a9);
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
