// Tranquil runtime functions

#import <Foundation/Foundation.h>

extern id TQSentinel;

enum TQBlockFlag_t {
    // I chose a flag right in the middle of the unused space, so let's hope Apple doesn't decide to use it
    TQ_BLOCK_IS_TRANQUIL_BLOCK = (1 << 19),
    TQ_BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
    TQ_BLOCK_HAS_CXX_OBJ =       (1 << 26),
    TQ_BLOCK_IS_GLOBAL =         (1 << 28),
    TQ_BLOCK_USE_STRET =         (1 << 29),
    TQ_BLOCK_HAS_SIGNATURE  =    (1 << 30)
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
    unsigned long int reserved;	// NULL
        unsigned long int size;  // sizeof(struct Block_literal_1)
    // optional helper functions
        void (*copy_helper)(void *dst, void *src);
        void (*dispose_helper)(void *src);
        // Only applicable if flags & TQ_BLOCK_IS_TRANQUIL_BLOCK is true
        short numArgs;
        bool isVariadic;
    } *descriptor;
    // imported variables
};


id TQRetainObject(id obj);
void TQReleaseObject(id obj);
id TQAutoreleaseObject(id obj);
id TQRetainAutoreleaseObject(id obj);

// Stores obj in a Block_ByRef, retaining it
id TQStoreStrongInByref(void *dstPtr, id obj);

// These implement support for dynamic instance variables (But use existing properties if available)
id TQValueForKey(id obj, char *key);
void TQSetValueForKey(id obj, char *key, id value);

BOOL TQObjectIsStackBlock(id obj);
id TQPrepareObjectForReturn(id obj);

// Looks up a class if it exists, otherwise registers it
Class TQGetOrCreateClass(const char *name, const char *superName);

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
extern SEL TQAddOpSel;
extern SEL TQSubOpSel;
extern SEL TQUnaryMinusOpSel;
extern SEL TQSetterOpSel;
extern SEL TQGetterOpSel;

extern SEL TQNumberWithDoubleSel;
extern SEL TQStringWithUTF8StringSel;
extern SEL TQPointerArrayWithObjectsSel;
extern SEL TQMapWithObjectsundKeysSel;
extern SEL TQRegexWithPatSel;

extern Class TQNumberClass;
