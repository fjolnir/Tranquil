#import <Tranquil/Runtime/TQRuntime.h>
#import <Tranquil/Runtime/TQObject.h>
#import <ffi/ffi.h>

@interface TQBlockClosure : NSObject {
    @public
    const char *_type;
    ffi_cif *_cif;
    ffi_closure *_closure;
    ffi_type **_argTypes;
    void *_functionPointer, *_pointer;
    struct TQBlockLiteral _boxedBlock;
    NSMutableArray *_ffiTypeObjects;
    id _block;
}
@property(readonly) void *pointer; // Points to a function pointer for <^..> and to a block for <@..>
- (id)initWithBlock:(id)aBlock type:(const char *)aType;
@end
