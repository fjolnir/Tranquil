// Supports boxing scalar, struct, union, pointer, array, block & function pointer types
#import <Tranquil/Runtime/TQObject.h>
#import <objc/runtime.h>
#import <objc/message.h>

#ifdef __cplusplus
extern "C" {
#endif

#define TQBoxedObject_PREFIX "TQBoxedObject_"
#define BlockImp imp_implementationWithBlock

#define TYPE_IS_TOLLFREE(t) ((*(t) == _C_PTR) && (strstr(t, "^{__CF") == (t) || strstr((t), "^{__AX") == (t) || strstr((t), "^{__TIS") == (t)))

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

#ifdef __cplusplus
}
#endif
