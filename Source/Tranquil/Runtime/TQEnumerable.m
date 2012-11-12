#import "TQEnumerable.h"
#import "TQRuntime.h"
#import "OFCollections+Tranquil.h"
#import "../../../Build/TQStubs.h"

@interface TQEnumerable (NotImplementedHere)
- (id)each:(id (^)(id))aBlock;
@end

@implementation TQEnumerable
+ (id)canBeIncludedInto:(Class)aClass
{
    return [aClass instancesRespondToSelector:@selector(each:)] ? TQValid : nil;
}

- (id)select:(id (^)(id))aBlock
{
    OFMutableArray *ret = [OFMutableArray new];
    [self each:^(id obj) {
        if(TQDispatchBlock1(aBlock, obj))
            [ret addObject:obj];
        return (id)nil;
    }];
    [ret autorelease];
    return [ret count] > 0 ? ret : nil;
}

- (id)select:(id (^)(id))aSelectBlock map:(id (^)(id))aMapBlock
{
    OFMutableArray *ret = [OFMutableArray new];
    [self each:^(id obj) {
        if(TQDispatchBlock1(aSelectBlock, obj))
            [ret addObject:TQDispatchBlock1(aMapBlock, obj)];
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
    OFMutableArray *ret = [OFMutableArray new];
    [self each:^(id obj) {
        [ret addObject:TQDispatchBlock1(aBlock, obj)];
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

- (OFMutableArray *)toArray
{
    OFMutableArray *ret = [OFMutableArray new];
    [self each:^(id obj) {
        [ret addObject:obj];
        return (id)nil;
    }];
    return [ret autorelease];
}

@end
