#import <Foundation/Foundation.h>

extern void *TQSentinel;

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
@end
