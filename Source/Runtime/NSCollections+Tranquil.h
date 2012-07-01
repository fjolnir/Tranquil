#import <Foundation/Foundation.h>
#import "TQRuntime.h"

@class TQNumber;

@interface NSMapTable (Tranquil)
+ (NSMapTable *)tq_mapTableWithObjectsAndKeys:(id)firstObject , ...; // Arguments terminated by TQSentinel
- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)obj forKeyedSubscript:(id)key;
@end

@interface NSPointerArray (Tranquil)
+ (NSPointerArray *)tq_pointerArrayWithObjects:(id)firstObject , ...;  // Arguments terminated by TQSentinel
- (void)setObject:(void*)aPtr atIndexedSubscript:(NSUInteger)aIdx;
- (id)objectAtIndexedSubscript:(NSUInteger)aIdx;
- (TQNumber *)tqCount;

- (id)push:(id)aObj;
- (id)last;
- (id)first;
- (id)pop;

- (id)each:(id (^)(id))aBlock;
- (NSPointerArray *)map:(id (^)(id))aBlock;
- (id)reduce:(id (^)(id, id))aBlock;
- (id)map:(id (^)(id))mapBlock reduce:(id (^)(id, id))reduceBlock;
@end
