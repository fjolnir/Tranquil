// Supports boxing scalar, struct, union, pointer, array, block & function pointer types
#import <Tranquil/Runtime/TQObject.h>
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

// The tranquil message dispatcher. Automatically performs any (un)boxing required for a message
// to be dispatched.
extern "C" id tq_msgSend(id self, SEL selector, ...);

// Sends a message boxing the return value and unboxing arguments as necessary
// WAY slower than objc_msgSend and should never be used directly.
// tq_msgSend is a more intelligent message dispatcher that calls tq_boxedMsgSend only if necessary
extern "C" id tq_boxedMsgSend(id self, SEL selector, ...);
