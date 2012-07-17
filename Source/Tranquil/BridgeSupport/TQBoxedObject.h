// Supports boxing scalar, struct, union, block & function pointer types
// TODO: Support arrays
#import <Tranquil/TQObject.h>
#import <objc/runtime.h>
#import <objc/message.h>

#define TQBoxedObject_PREFIX "TQBoxedObject_"
#define BlockImp imp_implementationWithBlock

#define TQBox(val) [TQBoxedObject box:&(val) withType:@encode(__typeof(val))]

@interface TQBoxedObject : TQObject {
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

- (void)moveValueToHeap;
@end

// Sends a message boxing the return value and unboxing arguments as necessary
// WAY slower than objc_msgSend so only use this if you have a reason to believe the method may have
// non-object parameters/return value
id TQBoxedMsgSend(id self, SEL selector, ...);
