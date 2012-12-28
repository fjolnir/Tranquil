#import <Foundation/Foundation.h>
#import <Tranquil/Runtime/TQObject.h>
#import <Tranquil/Shared/TQBatching.h>

@class TQNumber;

@interface NSMapTable (Tranquil)
+ (NSMapTable *)tq_mapTableWithObjectsAndKeys:(id)firstObject , ...; // Arguments terminated by TQNothing
- (id)at:(id)aKey;
- (id)each:(id (^)(id))aBlock;
- (id)add:(NSMapTable *)aOther;
@end

@interface NSPointerArray (Tranquil)
+ (NSPointerArray *)tq_pointerArrayWithObjects:(id)firstObject , ...;  // Arguments terminated by TQNothing
- (void)setObject:(id)aPtr atIndexedSubscript:(NSUInteger)aIdx;
- (void)removeObjectAtIndex:(NSUInteger)aIdx;
- (void)removeObject:(id)aObj;
- (id)objectAtIndexedSubscript:(NSUInteger)aIdx;
- (id)at:(TQNumber *)aIdx;
- (TQNumber *)size;
- (TQNumber *)indexOf:(id)aObj;

- (id)push:(id)aObj;
- (id)pop;
- (id)insert:(id)aObj at:(TQNumber *)aIdx;
- (id)remove:(id)aObj;
- (id)last;
- (id)first;

- (id)each:(id (^)(id))aBlock;
- (NSPointerArray *)multiply:(TQNumber *)aTimes;
- (id)append:(id<NSFastEnumeration>)aOther;
@end

#define INDEXED_SUBSCRIPT_DEFS \
    - (id)objectAtIndexedSubscript:(NSUInteger)idx NS_AVAILABLE(10_7, 5_0); \
    - (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx NS_AVAILABLE(10_7, 5_0);

#define KEYED_SUBSCRIPT_DEFS \
    - (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key NS_AVAILABLE(10_7, 5_0); \
    - (id)objectForKeyedSubscript:(id)key NS_AVAILABLE(10_7, 5_0);

@interface NSArray (Tranquil)
- (id)at:(TQNumber *)aIdx;
#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_7
- (id)objectAtIndexedSubscript:(NSUInteger)idx NS_AVAILABLE(10_7, 5_0);
#endif
@end
@interface NSMutableArray (Tranquil)
- (id)remove:(id)aObj;
#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_7
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx NS_AVAILABLE(10_7, 5_0);
#endif
@end

@interface NSDictionary (Tranquil)
- (id)at:(id)aKey;
#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_7
KEYED_SUBSCRIPT_DEFS
#endif
@end
@interface NSMutableDictionary (Tranquil)
- (id)set:(id)aKey to:(id)aVal;
@end

@interface NSUserDefaults (Tranquil)
KEYED_SUBSCRIPT_DEFS
@end

@interface NSCache (Tranquil)
KEYED_SUBSCRIPT_DEFS
@end

@interface TQPair : TQObject {
    TQ_BATCH_IVARS
}
@property(readwrite, strong) id left, right;
+ (TQPair *)with:(id)left and:(id)right;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (id)each:(id (^)(id))aBlock;
@end

