#import <Foundation/Foundation.h>
#import <Tranquil/Runtime/TQRuntime.h>

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
- (TQNumber *)size;

- (id)push:(id)aObj;
- (id)last;
- (id)first;
- (id)pop;

- (id)each:(id (^)(id))aBlock;
- (NSPointerArray *)map:(id (^)(id))aBlock;
- (id)reduce:(id (^)(id, id))aBlock;
- (id)map:(id (^)(id))mapBlock reduce:(id (^)(id, id))reduceBlock;
@end

#define INDEXED_SUBSCRIPT_DEFS \
    - (id)objectAtIndexedSubscript:(NSUInteger)idx NS_AVAILABLE(10_7, 5_0); \
    - (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx NS_AVAILABLE(10_7, 5_0);

#define KEYED_SUBSCRIPT_DEFS \
    - (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key NS_AVAILABLE(10_7, 5_0); \
    - (id)objectForKeyedSubscript:(id)key NS_AVAILABLE(10_7, 5_0);

#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_8
@interface NSArray (Tranquil)
INDEXED_SUBSCRIPT_DEFS
@end

@interface NSDictionary (Tranquil)
KEYED_SUBSCRIPT_DEFS
@end
#endif

@interface NSUserDefaults (Tranquil)
KEYED_SUBSCRIPT_DEFS
@end

@interface NSCache (Tranquil)
KEYED_SUBSCRIPT_DEFS
@end
