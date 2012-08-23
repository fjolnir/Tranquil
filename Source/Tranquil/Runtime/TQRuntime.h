// Tranquil runtime functions

#import <Foundation/Foundation.h>
#import <stdarg.h>
#import <Tranquil/Runtime/TQValidObject.h>
#import <Tranquil/Shared/TQDebug.h>

#ifdef __cplusplus
extern "C" {
#endif

// Extend objc/runtime.h and add function pointers and blocks tokens.
// A pointer to `void foo (int, char)' will be encoded as <^vic>.
// A `void (^)(int, char)' block will be encoded as <@vic>.
#define _TQ_C_LAMBDA_B        '<'
#define _TQ_C_LAMBDA_FUNCPTR  '^'
#define _TQ_C_LAMBDA_BLOCK    '@'
#define _TQ_C_LAMBDA_E        '>'

extern id TQSentinel;
extern TQValidObject *TQValid;

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
    unsigned long int reserved; // NULL
        unsigned long int size; // sizeof(struct TQBlockLiteral)
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

typedef void (^TQTypeIterationBlock)(const char *type, NSUInteger size, NSUInteger align, BOOL *stop);

// These implement support for dynamic instance variables (But use existing properties if available)
void TQSetValueForKey(id obj, char *key, id value);
id TQValueForKey(id obj, const char *key);

BOOL TQObjectIsStackBlock(id obj);
id TQPrepareObjectForReturn(id obj);
NSPointerArray *TQVaargsToArray(va_list *items);
NSPointerArray *TQCliArgsToArray(int argc, char **argv);

// Looks up a class if it exists, otherwise registers it
Class TQGetOrCreateClass(const char *name, const char *superName);
// Returns the superclass of the class of an object
Class TQObjectGetSuperClass(id aObj);
// Determines whether a method with a certain signature needs to be boxed
BOOL TQMethodTypeRequiresBoxing(const char *encoding);
// Unboxes an object into a buffer
void TQUnboxObject(id object, const char *type, void *buffer);
// Boxes a value into an object
id TQBoxValue(void *value, const char *type);
// Returns whether or not a struct of a given size must be returned by inserting a pointer argument in the argument list
// as opposed to returning it by value in a register
BOOL TQStructSizeRequiresStret(int size);
// NSGetSizeAndAlignment augmented to handle MacRuby lambda notation <@>
const char *TQGetSizeAndAlignment(const char *typePtr, NSUInteger *sizep, NSUInteger *alignp);
// Iterates the types in an encoding string by calling the passed block with each
void TQIterateTypesInEncoding(const char *typePtr, TQTypeIterationBlock blk);

// Returns the number of arguments a tranquil block takes (If the object is not a block originating from tranquil, it returns -1)
NSInteger TQBlockGetNumberOfArguments(id block);

// Tests objects for equality (including nil)
id TQObjectsAreEqual(id a, id b);
// Tests objects for inequality (including nil)
id TQObjectsAreNotEqual(id a, id b);

// Adds operator methods to the passed class (such as ==:, >=:, []: etc)
BOOL TQAugmentClassWithOperators(Class klass);

void TQInitializeRuntime();

extern SEL TQEqOpSel;
extern SEL TQNeqOpSel;
extern SEL TQLTOpSel;
extern SEL TQGTOpSel;
extern SEL TQGTEOpSel;
extern SEL TQLTEOpSel;
extern SEL TQMultOpSel;
extern SEL TQDivOpSel;
extern SEL TQModOpSel;
extern SEL TQAddOpSel;
extern SEL TQSubOpSel;
extern SEL TQUnaryMinusOpSel;
extern SEL TQLShiftOpSel;
extern SEL TQRShiftOpSel;
extern SEL TQConcatOpSel;
extern SEL TQSetterOpSel;
extern SEL TQGetterOpSel;
extern SEL TQExpOpSel;

extern SEL TQNumberWithDoubleSel;
extern SEL TQStringWithUTF8StringSel;
extern SEL TQStringWithFormatSel;
extern SEL TQPointerArrayWithObjectsSel;
extern SEL TQMapWithObjectsAndKeysSel;
extern SEL TQRegexWithPatSel;
extern SEL TQMoveToHeapSel;
extern SEL TQWeakSel;

extern Class TQNumberClass;

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
