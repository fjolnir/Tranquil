#import "NSCollections+Tranquil.h"
#import "TQRuntime.h"
#import "../../../Build/TQStubs.h"
#import "TQNumber.h"
#import <objc/runtime.h>
#import "NSObject+TQAdditions.h"
#import "TQEnumerable.h"

@interface TQPointerArrayEnumerator : NSEnumerator {
    NSPointerArray *_array;
    NSUInteger _currIdx;
}
+ (TQPointerArrayEnumerator *)enumeratorWithArray:(NSPointerArray *)aArray;
@end

@implementation NSMapTable (Tranquil)
+ (void)load
{
    [self include:[TQEnumerable class]];
}
+ (NSMapTable *)tq_mapTableWithObjectsAndKeys:(id)firstObject, ...
{
    NSMapTable *ret = [NSMapTable new];

    va_list args;
    va_start(args, firstObject);
    id key, val, head;
    int i = 0;
    IMP setImp = class_getMethodImplementation(object_getClass(ret), @selector(setObject:forKey:));
    for(head = firstObject; head != TQNothing; head = va_arg(args, id))
    {
        if(++i % 2 == 0) {
            key = head;
            setImp(ret, @selector(setObject:forKey:), val, key);
        } else
            val = TQObjectIsStackBlock(head) ? [[head copy] autorelease] : head;
    }
    va_end(args);

    return [ret autorelease];
}

- (id)objectForKeyedSubscript:(id)aKey
{
    return [self objectForKey:aKey];
}

- (void)setObject:(id)aObj forKeyedSubscript:(id)aKey
{
    [self setObject:TQObjectIsStackBlock(aObj) ? [[aObj copy] autorelease] : aObj forKey:aKey];
}

- (id)each:(id (^)(id))aBlock
{
    id res;
    for(id key in self) {
        res = TQDispatchBlock1(aBlock, [TQPair with:key and:[self objectForKey:key]]);
        if(res == TQNothing)
            break;
    }
    return nil;
}
@end

@implementation NSPointerArray (Tranquil)
+ (void)load
{
    [self include:[TQEnumerable class]];
}

+ (NSPointerArray *)tq_pointerArrayWithObjects:(id)firstObject , ...
{
    NSPointerArray *ret = [NSPointerArray new];

    va_list args;
    va_start(args, firstObject);
    IMP addImp = class_getMethodImplementation(object_getClass(ret), @selector(addPointer:));
    for(id item = firstObject; item != TQNothing; item = va_arg(args, id))
    {
        addImp(ret, @selector(addPointer:), item);
    }
    va_end(args);

    return [ret autorelease];
}

#pragma mark NSMutableArray compatibility
- (void)addObject:(id)aObj
{
    [self addPointer:TQObjectIsStackBlock(aObj) ? [[aObj copy] autorelease] : aObj];
}

- (void)insertObject:(id)aObj atIndex:(NSUInteger)aIdx
{
    [self setObject:(id)aObj atIndexedSubscript:aIdx];
}

- (id)objectAtIndex:(NSUInteger)aIdx
{
    return (id)[self pointerAtIndex:aIdx];
}

- (void)setObject:(id)aObj atIndexedSubscript:(NSUInteger)aIdx
{
    NSUInteger count = [self count];
    if(aIdx < count) {
        [self replacePointerAtIndex:aIdx
                        withPointer:TQObjectIsStackBlock(aObj) ? [[aObj copy] autorelease] : aObj];
    } else if(aIdx == count)
        [self addObject:aObj];
    else
        assert(false);
}

- (id)objectAtIndexedSubscript:(NSUInteger)aIdx
{
    if(aIdx < [self count])
        return (id)[self pointerAtIndex:aIdx];
    else
        return nil;
}

- (id)lastObject
{
    NSUInteger count = [self count];
    return count == 0 ? nil : [self objectAtIndex:count-1];
}

- (void)removeObjectAtIndex:(NSUInteger)aIdx
{
    [self removePointerAtIndex:aIdx];
}

- (void)removeLastObject
{
    NSUInteger count = [self count];
    if(count > 0)
        [self removeObjectAtIndex:count-1];
}

- (id)each:(id (^)(id))aBlock
{
    for(id obj in self) {
        if(TQDispatchBlock1(aBlock, obj) == TQNothing)
            break;
    }
    return nil;
}


#pragma mark - Helpers

- (TQNumber *)size
{
    return [TQNumber numberWithDouble:(double)[self count]];
}

- (BOOL)containsObject:(id)aObj
{
    for(id obj in self) {
        if([obj isEqual:aObj])
            return YES;
    }
    return NO;
}

- (id)contains:(id)aObj
{
    return [self containsObject:aObj] ? TQValid : nil;
}

- (TQNumber *)indexOf:(id)aObj
{
    NSUInteger idx = 0;
    for(id obj in self) {
        if(tq_msgSend_noBoxing(aObj, TQEqOpSel, obj))
            return [TQNumber numberWithUnsignedInteger:idx];
        ++idx;
    }
    return [TQNumber numberWithInteger:-1];
}

- (id)push:(id)aObj
{
    [self addObject:aObj];
    return self;
}

- (id)pop
{
    id val = [self last];
    [self removePointerAtIndex:[self count]-1];
    return val;
}

- (id)insert:(id)aObj at:(TQNumber *)aIdx
{
    NSUInteger idx = [aIdx unsignedIntegerValue];
    if(idx == [self count])
        [self addPointer:aObj];
    else
        [self insertPointer:aObj atIndex:[aIdx unsignedIntegerValue]];
    return nil;
}

- (id)removeObject:(id)aObj
{
    NSMutableIndexSet *indices = [NSMutableIndexSet indexSet];
    NSUInteger i = 0;
    for(id obj in self) {
        if(tq_msgSend_noBoxing(aObj, TQEqOpSel, obj))
            [indices addIndex:i];
        ++i;
    }
    [indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self removePointerAtIndex:idx];
    }];
    return nil;
}

- (id)last
{
    return (id)[self pointerAtIndex:[self count]-1];
}

- (id)first
{
    return (id)[self pointerAtIndex:0];
}

- (id)add:(NSPointerArray *)aArray // add: as in +
{
    NSPointerArray *result = [NSPointerArray new];
    for(id obj in self)
        [result push:obj];
    for(id obj in aArray)
        [result push:obj];
    return [result autorelease];
}

- (id)subtract:(NSPointerArray *)aArray
{
    NSPointerArray *result = [NSPointerArray new];
    for(id obj in self) {
        if(![aArray containsObject:obj])
            [result push:obj];
    }
    return [result autorelease];
}

#pragma mark - Iterators

- (NSEnumerator *)objectEnumerator
{
    return [TQPointerArrayEnumerator enumeratorWithArray:self];
}

- (id)concat
{
    return [(id)self reduce:^(id subArray, id accum) {
        if(accum == TQNothing)
            accum = [[[self class] new] autorelease];
        return [subArray reduce:^(id obj, id _) {
             return [accum push:obj];
        }];
    }];
}

- (id)zip:(NSPointerArray *)otherArray {
    NSUInteger length = [self count];
    if([otherArray count] > length)
        length = [otherArray count];
    id result = [[self class] new];
    for(int i = 0; i < length; ++i) {
        [result push:[self       objectAtIndexedSubscript:i]];
        [result push:[otherArray objectAtIndexedSubscript:i]];
    }
    return [result autorelease];
}

- (NSString *)description
{
    NSMutableString *out = [NSMutableString stringWithFormat:@"<%@: %p", [self class], self];
    for(id obj in self) {
        [out appendFormat:@" %@,\n", obj];
    }
    [out appendString:@">"];
    return out;
}
@end

@implementation NSArray (Tranquil)
+ (void)load
{
    [self include:[TQEnumerable class]];
}
- (id)each:(id (^)(id))aBlock
{
    for(id obj in self) {
        if(TQDispatchBlock1(aBlock, obj) == TQNothing)
            break;
    }
    return nil;
}


#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_7
- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    return [self objectAtIndex:idx];
}
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
    [(NSMutableArray *)self replaceObjectAtIndex:idx withObject:obj];
}
#endif

@end

@implementation NSDictionary (Tranquil)
+ (void)load
{
    [self include:[TQEnumerable class]];
}
- (id)each:(id (^)(id))aBlock
{
    id res;
    for(id key in self) {
        res = TQDispatchBlock1(aBlock, [TQPair with:key and:[self objectForKey:key]]);
        if(res == TQNothing)
            break;
    }
    return nil;
}

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_7
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key
{
    [(NSMutableDictionary *)self setObject:obj forKey:key];
}
- (id)objectForKeyedSubscript:(id)key
{
    return [self objectForKey:key];
}
#endif
@end

@implementation NSUserDefaults (Tranquil)
- (void)setObject:(id)obj forKeyedSubscript:(id <NSObject,NSCopying>)key
{
    NSAssert([key isKindOfClass:[NSString class]], @"User defaults keys must be strings!");
    [self setObject:obj forKey:(NSString *)key];
}
- (id)objectForKeyedSubscript:(id)key
{
    return [self objectForKey:key];
}
@end

@implementation NSCache (Tranquil)
- (void)setObject:(id)obj forKeyedSubscript:(id <NSObject,NSCopying>)key
{
    [self setObject:obj forKey:(NSString *)key];
}
- (id)objectForKeyedSubscript:(id)key
{
    return [self objectForKey:key];
}
@end


#pragma mark -

@implementation TQPointerArrayEnumerator
+ (TQPointerArrayEnumerator *)enumeratorWithArray:(NSPointerArray *)aArray
{
    TQPointerArrayEnumerator *ret = [self new];
    ret->_array = [aArray retain];
    return [ret autorelease];
}
- (void)dealloc
{
    [_array release];
    [super dealloc];
}
- (id)nextObject
{
    if(_currIdx >= [_array count])
        return nil;
    return [_array pointerAtIndex:_currIdx++];
}

- (NSArray *)allObjects
{
    return [_array allObjects];
}
@end

@implementation TQPair
+ (void)load
{
    [self include:[TQEnumerable class]];
}
+ (TQPair *)with:(id)left and:(id)right
{
    TQPair *ret = [self new];
    ret.left = left;
    ret.right = right;
    return [ret autorelease];
}
- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    switch(idx) {
        case 0:
            return _left;
        case 1:
            return _right;
        default:
            return nil;
    }
}
- (id)each:(id (^)(id))aBlock
{
    if(TQDispatchBlock1(aBlock, _left) == TQNothing)
        return nil;
    TQDispatchBlock1(aBlock, _right);
    return nil;
}
- (NSString *)description
{
    return [NSString stringWithFormat:@"<pair: %@, %@>", _left, _right];
}
#pragma mark - Batch allocation code
TQ_BATCH_IMPL(TQPair)
- (void)dealloc
{
    TQ_BATCH_DEALLOC
}
@end

