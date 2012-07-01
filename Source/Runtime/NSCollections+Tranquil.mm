#import "NSCollections+Tranquil.h"
#import <objc/runtime.h>

// Just a unique address
void *TQSentinel = (void*)@"3d2c9ac0bf3911e1afa70800200c9a66aaaaaaaaa";

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
@end
