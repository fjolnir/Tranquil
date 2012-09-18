#import "NSCollections+Tranquil.h"
#import "../../../Build/TQStubs.h"
#import "TQNumber.h"
#import <objc/runtime.h>

@interface TQPointerArrayEnumerator : NSEnumerator {
    NSPointerArray *_array;
    NSUInteger _currIdx;
}
+ (TQPointerArrayEnumerator *)enumeratorWithArray:(NSPointerArray *)aArray;
@end


@implementation NSMapTable (Tranquil)
+ (NSMapTable *)tq_mapTableWithObjectsAndKeys:(id)firstObject, ...
{
    NSMapTable *ret = [NSMapTable new];

    va_list args;
    va_start(args, firstObject);
    id key, val, head;
    int i = 0;
    IMP setImp = class_getMethodImplementation(object_getClass(ret), @selector(setObject:forKey:));
    for(head = firstObject; head != TQSentinel; head = va_arg(args, id))
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
@end

@implementation NSPointerArray (Tranquil)
+ (NSPointerArray *)tq_pointerArrayWithObjects:(id)firstObject , ...
{
    NSPointerArray *ret = [NSPointerArray new];

    va_list args;
    va_start(args, firstObject);
    IMP addImp = class_getMethodImplementation(object_getClass(ret), @selector(addPointer:));
    for(id item = firstObject; item != TQSentinel; item = va_arg(args, id))
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


#pragma mark - Helpers

- (TQNumber *)size
{
    return [TQNumber numberWithDouble:(double)[self count]];
}

- (id)push:(id)aObj
{
    [self addObject:aObj];
    return self;
}

- (id)last
{
    return (id)[self pointerAtIndex:[self count]-1];
}

- (id)first
{
    return (id)[self pointerAtIndex:0];
}

- (id)pop
{
    id val = [self last];
    [self removePointerAtIndex:[self count]-1];
    return val;
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

#pragma mark - Iterators

- (NSEnumerator *)objectEnumerator
{
    return [TQPointerArrayEnumerator enumeratorWithArray:self];
}

- (id)each:(id (^)(id))aBlock
{
    for(id obj in self) {
        TQDispatchBlock1(aBlock, obj);
    }
    return nil;
}

- (id)map:(id (^)(id))aBlock
{
    id ret = [[self class] new];
    for(id obj in self) {
        [ret push:TQDispatchBlock1(aBlock, obj)];
    }
    return [ret autorelease];
}

- (id)reduce:(id (^)(id, id))aBlock
{
    id accum = TQSentinel; // Make the block use it's default accumulator on the first call
    for(id obj in self) {
        accum = TQDispatchBlock2(aBlock, obj, accum);
    }
    return accum;
}

- (id)map:(id (^)(id))mapBlock reduce:(id (^)(id, id))reduceBlock
{
    return [[self map:mapBlock] reduce:reduceBlock];
}

- (id)concat
{
    return [self reduce:^(id subArray, id accum) {
        if(accum == TQSentinel)
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

