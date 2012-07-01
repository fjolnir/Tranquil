#import <Foundation/Foundation.h>

extern void *TQSentinel;

@interface NSMapTable (Tranquil)
+ (NSMapTable *)tq_mapTableWithObjectsAndKeys:(id)firstObject , ...; // Arguments terminated by TQSentinel
@end

@interface NSPointerArray (Tranquil)
+ (NSPointerArray *)tq_pointerArrayWithObjects:(id)firstObject , ...;  // Arguments terminated by TQSentinel
- (void)tq_setPointer:(void*)aPtr atIndex:(NSUInteger)aIdx;
@end
