#import "NSCollections+Tranquil.h"
#import "TQNumber.h"
#import <objc/runtime.h>

// Just a unique address
id TQSentinel = @"3d2c9ac0bf3911e1afa70800200c9a66aaaaaaaaa";

@implementation NSMapTable (Tranquil)
+ (NSMapTable *)tq_mapTableWithObjectsAndKeys:(id)firstObject , ...
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
+ (NSMapTable *)tq_pointerArrayWithObjects:(id)firstObject , ...
{
    NSMapTable *ret = [NSPointerArray pointerArrayWithStrongObjects];

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
    return (id)[self pointerAtIndex:aIdx];
}

- (TQNumber *)tqCount
{
    return [TQNumber numberWithDouble:(double)[self count]];
}

#pragma mark - Helpers

- (id)push:(id)aObj
{
    [self addPointer:aObj];
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

- (id)pop
{
    id val = [self last];
    [self removePointerAtIndex:[self count]-1];
    return val;
}
#pragma mark - Iterators

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
    // The default args are not implemented so this method won't actually work yet.
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

@end
