#import <Foundation/Foundation.h>
#import <stdarg.h>
#import <Tranquil/Runtime/TQValidObject.h>
#import <Tranquil/Shared/TQDebug.h>

#ifdef __cplusplus
extern "C" {
#endif

enum TQBlockFlag_t {
    // I chose a flag right in the middle of the unused space, so let's hope Apple doesn't decide to use it
    TQ_BLOCK_IS_TRANQUIL_BLOCK = (1 << 19),
    TQ_BLOCK_HAS_COPY_DISPOSE  = (1 << 25),
    TQ_BLOCK_HAS_CXX_OBJ       = (1 << 26),
    TQ_BLOCK_IS_GLOBAL         = (1 << 28),
    TQ_BLOCK_USE_STRET         = (1 << 29),
    TQ_BLOCK_HAS_SIGNATURE     = (1 << 30)
};

enum TQBlockFieldFlag_t {
    TQ_BLOCK_FIELD_IS_OBJECT   = 0x03,  // id, NSObject, __attribute__((NSObject)), block, ..
    TQ_BLOCK_FIELD_IS_BLOCK    = 0x07,  // a block variable
    TQ_BLOCK_FIELD_IS_BYREF    = 0x08,  // the on stack structure holding the __block variable
    TQ_BLOCK_FIELD_IS_WEAK     = 0x10,  // declared __weak, only used in byref copy helpers
    TQ_BLOCK_FIELD_IS_ARC      = 0x40,  // field has ARC-specific semantics */
    TQ_BLOCK_BYREF_CALLER      = 128,   // called from __block (byref) copy/dispose support routines
    TQ_BLOCK_BYREF_CURRENT_MAX = 256
};

struct TQBlockLiteral {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    id (*invoke)(void *, ...);
    struct TQBlockDescriptor {
        unsigned long reserved; // NULL
        unsigned long size; // sizeof(struct TQBlockLiteral)
    // optional helper functions
        void (*copy_helper)(void *dst, void *src);
        void (*dispose_helper)(void *src);
        char *signature;
        void *gcInfo; // Unused in objc2
        // Only applicable if flags & TQ_BLOCK_IS_TRANQUIL_BLOCK is true
        int32_t numArgs;
        BOOL isVariadic;
    } *descriptor;
    // imported variables
};

// Memory layout for a __block variable
struct TQBlockByRef {
    id isa;
    struct TQBlockByRef *forwarding;
    int flags, size;
    id value;
};

// ARC
id objc_retain(id obj) __asm__("_objc_retain");
void objc_release(id obj) __asm__("_objc_release");
id objc_autorelease(id obj) __asm__("_objc_autorelease");
// wraps objc_autorelease(obj) in a useful way when used with return values
id objc_autoreleaseReturnValue(id obj);
// wraps objc_autorelease(objc_retain(obj)) in a useful way when used with return values
id objc_retainAutoreleaseReturnValue(id obj);
// called ONLY by ARR by callers to undo the autorelease (if possible), otherwise objc_retain
id objc_retainAutoreleasedReturnValue(id obj);
id objc_retainAutorelease(id obj);

void objc_storeStrong(id *location, id obj);

id objc_loadWeakRetained(id *location);
id  objc_initWeak(id *addr, id val);
void objc_destroyWeak(id *addr);
void objc_copyWeak(id *to, id *from);
void objc_moveWeak(id *to, id *from);

#ifdef __cplusplus
}
#endif
