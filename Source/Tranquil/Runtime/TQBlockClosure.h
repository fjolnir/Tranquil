#import <Tranquil/Runtime/TQRuntime.h>
#import <Tranquil/Runtime/TQObject.h>
#import <ffi.h>

@class TQBlockClosure;

struct TQClosureBlockLiteral {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    id (*invoke)(void *, ...);
    struct TQClosureBlockDescriptor {
        unsigned long int reserved, size;
        void (*copy_helper)(struct TQClosureBlockLiteral *dst, struct TQClosureBlockLiteral *src);
        void (*dispose_helper)(struct TQClosureBlockLiteral *src);
    } *descriptor;
    TQBlockClosure *closure;
};

@interface TQBlockClosure : NSObject {
    @public
    const char *_type;
    ffi_cif *_cif;
    ffi_closure *_closure;
    ffi_type **_argTypes;
    void *_functionPointer, *_pointer;
    struct TQClosureBlockLiteral _boxedBlock;
    NSMutableArray *_ffiTypeObjects;
    id _block;
}
@property(readonly) void *pointer; // Points to a function pointer for <^..> and to a block for <@..>
- (id)initWithBlock:(id)aBlock type:(const char *)aType;
@end
