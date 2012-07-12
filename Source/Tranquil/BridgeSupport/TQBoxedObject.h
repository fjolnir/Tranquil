// Supports boxing scalar, struct, union, block & function pointer types
// TODO: Support arrays
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

#define TQBoxedObject_PREFIX "TQBoxedObject_"
#define BlockImp imp_implementationWithBlock

#define TQBox(val) [TQBoxedObject box:&(val) withType:@encode(__typeof(val))]

@interface TQBoxedObject : NSObject {
    @protected
    void *_ptr; // Points to the boxed value
    NSUInteger _size;
    BOOL _isOnHeap;
}
@property(readonly) void *valuePtr;

+ (TQBoxedObject *)box:(void *)aPtr;
+ (TQBoxedObject *)box:(void *)aPtr withType:(const char *)aType;
- (id)initWithPtr:(void *)aPtr;
+ (void)unbox:(id)aValue to:(void *)aDest usingType:(const char *)aType;
+ (BOOL)typeIsScalar:(const char *)aType;

- (id)objectAtIndexedSubscript:(NSInteger)aIdx;
- (void)setObject:(id)aValue atIndexedSubscript:(NSInteger)aIdx;

@end
