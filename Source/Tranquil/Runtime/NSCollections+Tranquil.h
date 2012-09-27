#import <Foundation/Foundation.h>
#import <Tranquil/Runtime/TQRuntime.h>

@class TQNumber;

@interface NSMapTable (Tranquil)
+ (NSMapTable *)tq_mapTableWithObjectsAndKeys:(id)firstObject , ...; // Arguments terminated by TQNothing
- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)obj forKeyedSubscript:(id)key;

- (id)each:(id (^)(id))aBlock;
@end

@interface NSPointerArray (Tranquil)
+ (NSPointerArray *)tq_pointerArrayWithObjects:(id)firstObject , ...;  // Arguments terminated by TQNothing
- (void)setObject:(id)aPtr atIndexedSubscript:(NSUInteger)aIdx;
- (id)objectAtIndexedSubscript:(NSUInteger)aIdx;
- (TQNumber *)size;

- (id)push:(id)aObj;
- (id)last;
- (id)first;
- (id)pop;

- (id)each:(id (^)(id))aBlock;
@end

#define INDEXED_SUBSCRIPT_DEFS \
    - (id)objectAtIndexedSubscript:(NSUInteger)idx NS_AVAILABLE(10_7, 5_0); \
    - (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx NS_AVAILABLE(10_7, 5_0);

#define KEYED_SUBSCRIPT_DEFS \
    - (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key NS_AVAILABLE(10_7, 5_0); \
    - (id)objectForKeyedSubscript:(id)key NS_AVAILABLE(10_7, 5_0);

@interface NSArray (Tranquil)
#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_8
INDEXED_SUBSCRIPT_DEFS
#endif
@end

@interface NSDictionary (Tranquil)
#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_8
KEYED_SUBSCRIPT_DEFS
#endif
@end

@interface NSUserDefaults (Tranquil)
KEYED_SUBSCRIPT_DEFS
@end

@interface NSCache (Tranquil)
KEYED_SUBSCRIPT_DEFS
@end
