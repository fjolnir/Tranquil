#import "OFCollections+Tranquil.h"
#import "TQRuntime.h"
#import "../../../Build/TQStubs.h"
#import "TQNumber.h"
#import <objc/runtime.h>
#import "OFObject+TQAdditions.h"
#import "TQEnumerable.h"

@implementation OFDictionary (Tranquil)
+ (void)load
{
    [self include:[TQEnumerable class]];
}
+ (OFDictionary *)tq_dictionaryWithObjectsAndKeys:(id)firstObject, ...
{
    OFMutableDictionary *ret = [OFMutableDictionary new];

    va_list args;
    va_start(args, firstObject);
    id key, val, head;
    int i = 0;
    for(head = firstObject; head != TQNothing; head = va_arg(args, id))
    {
        if(++i % 2 == 0) {
            key = head;
            [ret setObject:val forKey:key];
        } else
            val = TQObjectIsStackBlock(head) ? [[head copy] autorelease] : head;
    }
    va_end(args);

    [ret makeImmutable];
    return [ret autorelease];
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

@implementation OFArray (Tranquil)
+ (void)load
{
    [self include:[TQEnumerable class]];
}

+ (OFArray *)tq_arrayWithObjects:(id)firstObject , ...
{
    OFMutableArray *ret = [OFMutableArray new];

    va_list args;
    va_start(args, firstObject);
    for(id item = firstObject; item != TQNothing; item = va_arg(args, id))
    {
        [ret addObject:item];
    }
    va_end(args);

    [ret makeImmutable];
    return [ret autorelease];
}

- (id)each:(id (^)(id))aBlock
{
    for(id obj in self) {
        if(TQDispatchBlock1(aBlock, obj) == TQNothing)
            break;
    }
    return nil;
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
- (id)objectAtIndexedSubscript:(unsigned long)idx
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
- (OFString *)description
{
    return [OFString stringWithFormat:@"<pair: %@, %@>", _left, _right];
}
#pragma mark - Batch allocation code
TQ_BATCH_IMPL(TQPair)
- (void)dealloc
{
    TQ_BATCH_DEALLOC
}
@end

