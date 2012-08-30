#import "NSCollections+Tranquil.h"
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
    NSMapTable *ret = [NSMapTable mapTableWithStrongToStrongObjects];

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
            val = head;
    }
    va_end(args);

    return ret;
}

- (id)objectForKeyedSubscript:(id)key
{
    return [self objectForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id)key
{
    [self setObject:obj forKey:key];
}
@end

@implementation NSPointerArray (Tranquil)
+ (NSPointerArray *)tq_pointerArrayWithObjects:(id)firstObject , ...
{
    NSPointerArray *ret = [NSPointerArray pointerArrayWithStrongObjects];

    va_list args;
    va_start(args, firstObject);
    IMP addImp = class_getMethodImplementation(object_getClass(ret), @selector(addPointer:));
    for(id item = firstObject; item != TQSentinel; item = va_arg(args, id))
    {
        addImp(ret, @selector(addPointer:), item);
    }
    va_end(args);

    return ret;
}

- (id)objectAtIndex:(NSUInteger)aIdx
{
    return (id)[self pointerAtIndex:aIdx];
}

- (void)setObject:(void*)aPtr atIndexedSubscript:(NSUInteger)aIdx
{
    NSUInteger count = [self count];
    if(aIdx < count)
        [self replacePointerAtIndex:aIdx withPointer:aPtr];
    else if(aIdx == count)
        [self addPointer:aPtr];
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

- (TQNumber *)size
{
    return [TQNumber numberWithDouble:(double)[self count]];
}

#pragma mark - Helpers

- (id)push:(id)aObj
{
    [self addPointer:aObj];
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

- (id)add:(NSPointerArray *)aArray
{
    NSPointerArray *result = [NSPointerArray pointerArrayWithStrongObjects];
    for(id obj in self)
        [result push:obj];
    for(id obj in aArray)
        [result push:obj];
    return result;
}

#pragma mark - Iterators

- (NSEnumerator *)objectEnumerator
{
    return [TQPointerArrayEnumerator enumeratorWithArray:self];
}

- (id)each:(id (^)(id))aBlock
{
    for(id obj in self) {
        aBlock(obj);
    }
    return nil;
}

- (NSPointerArray *)map:(id (^)(id))aBlock
{
    NSPointerArray *ret = [NSPointerArray pointerArrayWithStrongObjects];

    for(id obj in self) {
        [ret addPointer:aBlock(obj)];
    }
    return ret;
}

- (id)reduce:(id (^)(id, id))aBlock
{
    id accum = TQSentinel; // Make the block use it's default accumulator on the first call
    for(id obj in self) {
        accum = aBlock(obj, accum);
    }
    return accum;
}

- (id)map:(id (^)(id))mapBlock reduce:(id (^)(id, id))reduceBlock
{
    return [[self map:mapBlock] reduce:reduceBlock];
}

- (id)concat
{
    return [self reduce:^(NSPointerArray *subArray, NSPointerArray *accum) {
        if(accum == TQSentinel)
            accum = [NSPointerArray pointerArrayWithStrongObjects];
        return [subArray reduce:^(id obj, id _) {
             return [accum push:obj];
        }];
    }];
}

- (id)zip:(NSPointerArray *)otherArray {
    NSUInteger length = [self count];
    if([otherArray count] > length)
        length = [otherArray count];
    NSPointerArray *result = [NSPointerArray pointerArrayWithStrongObjects];
    for(int i = 0; i < length; ++i) {
        [result push:[self       objectAtIndexedSubscript:i]];
        [result push:[otherArray objectAtIndexedSubscript:i]];
    }
    return result;
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

@implementation NSUserDefaults (WBSubscripts)
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

@implementation NSCache (WBSubscripts)
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

