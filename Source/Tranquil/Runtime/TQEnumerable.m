#import "TQEnumerable.h"
#import "TQRuntime.h"
#import "NSCollections+Tranquil.h"
#import "../../../Build/TQStubs.h"

@interface TQEnumerable (NotImplementedHere)
- (id)each:(id (^)(id))aBlock;
- (id)at:(id)loc;
- (id)set:(id)loc to:(id)val;
@end

@implementation TQEnumerable
+ (id)canBeIncludedInto:(Class)aClass
{
    return [aClass instancesRespondToSelector:@selector(each:)] ? [TQValidObject valid] : nil;
}

- (id)select:(id (^)(id))aBlock
{
    NSPointerArray *ret = [NSPointerArray new];
    [self each:^(id obj) {
        if(TQDispatchBlock1(aBlock, obj))
            [ret push:obj];
        return (id)nil;
    }];
    [ret autorelease];
    return [ret count] > 0 ? ret : nil;
}

- (id)select:(id (^)(id))aSelectBlock map:(id (^)(id))aMapBlock
{
    NSPointerArray *ret = [NSPointerArray new];
    [self each:^(id obj) {
        if(TQDispatchBlock1(aSelectBlock, obj))
            [ret push:TQDispatchBlock1(aMapBlock, obj)];
        return (id)nil;
    }];
    [ret autorelease];
    return [ret count] > 0 ? ret : nil;
}

- (id)find:(id (^)(id))aBlock
{
    __block id ret = nil;
    [self each:^(id obj) {
        if(TQDispatchBlock1(aBlock, obj)) {
            ret = obj;
            return TQNothing;
        }
        return (id)nil;
    }];
    return ret;
}

- (id)map:(id (^)(id))aBlock
{
    NSPointerArray *ret = [NSPointerArray new];
    [self each:^(id obj) {
        [ret push:TQDispatchBlock1(aBlock, obj)];
        return (id)nil;
    }];
    return [ret autorelease];
}

- (id)reduce:(id (^)(id, id))aBlock
{
    __block id accum = TQNothing; // Make the block use it's default accumulator on the first call
    [self each:^(id obj) {
        accum = TQDispatchBlock2(aBlock, obj, accum);
        return (id)nil;
    }];
    return accum;
}

- (id)map:(id (^)(id))aMapBlock reduce:(id (^)(id, id))aReduceBlock
{
    __block id accum = TQNothing;
    [self each:^(id obj) {
        obj   = TQDispatchBlock1(aMapBlock, obj);
        accum = TQDispatchBlock2(aReduceBlock, obj, accum);
        return (id)nil;
    }];
    return accum;
}

- (id)swap:(id)a with:(id)b
{
    id temp = [self at:a];
    [self set:a to:[self at:b]];
    [self set:b to:temp];
    return nil;
}

- (NSPointerArray *)toArray
{
    NSPointerArray *ret = [NSPointerArray new];
    [self each:^(id obj) {
        [ret push:obj];
        return (id)nil;
    }];
    return [ret autorelease];
}

@end
