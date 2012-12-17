#import <Foundation/NSPointerArray.h>
#import <Tranquil/Runtime/TQModule.h>

@interface TQEnumerable : TQModule
- (id)select:(id (^)(id))aBlock;
- (id)find:(id (^)(id))aBlock;
- (id)map:(id (^)(id))aBlock;
- (id)select:(id (^)(id))aSelectBlock map:(id (^)(id))aMapBlock;
- (id)reduce:(id (^)(id, id))aBlock;
- (id)map:(id (^)(id))aMapBlock reduce:(id (^)(id, id))aReduceBlock;
- (id)swap:(id)a with:(id)b;
- (NSPointerArray *)toArray;
@end
