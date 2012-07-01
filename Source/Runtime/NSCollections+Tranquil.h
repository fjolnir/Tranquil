#import <Foundation/Foundation.h>

extern void *TQSentinel;

@interface NSMapTable (Tranquil)
+ (NSMapTable *)tq_mapTableWithObjectsAndKeys:(id)firstObject , ...; // Arguments terminated by TQSentinel
@end

@interface NSPointerArray (Tranquil)
+ (NSMapTable *)tq_pointerArrayWithObjects:(id)firstObject , ...;  // Arguments terminated by TQSentinel
@end
