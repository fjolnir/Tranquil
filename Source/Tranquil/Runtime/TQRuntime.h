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

extern id TQNothing;
extern id TQValid;

typedef void (^TQTypeIterationBlock)(const char *type, NSUInteger size, NSUInteger align, BOOL *stop);

typedef enum {
    kTQArchitectureHost,
    kTQArchitectureI386,
    kTQArchitectureX86_64,
    kTQArchitectureARMv7
} TQArchitecture;

// The tranquil message dispatcher. Automatically performs any (un)boxing required for a message
// to be dispatched.
id tq_msgSend(id self, SEL selector, ...);

// Same as above except does not perform any (un)boxing
id tq_msgSend_noBoxing(id self, SEL selector, ...);
// Same as above except does not perform any (un)boxing
id tq_msgSend_noBoxing(id self, SEL selector, ...);

// Sends a message boxing the return value and unboxing arguments as necessary
// WAY slower than objc_msgSend and should never be used directly.
// tq_msgSend is a more intelligent message dispatcher that calls tq_boxedMsgSend only if necessary
id tq_boxedMsgSend(id self, SEL selector, ...);

// These implement support for dynamic instance variables (But use existing properties if available)
NSMutableDictionary *TQGetDynamicIvarTable(id obj);
void TQSetValueForKey(id obj, NSString *key, id value);
id TQValueForKey(id obj, NSString *key);

BOOL TQObjectIsStackBlock(id obj);
id TQPrepareObjectForReturn(id obj);
// Variant of objc_storeStrong that moves stack blocks to the heap
void TQStoreStrong(id *location, id obj);
NSPointerArray *TQVaargsToArray(va_list *items);

// Looks up a class if it exists, otherwise registers it
Class TQGetOrCreateClass(const char *name, const char *superName);
// Looks up a class and crashes if it doesn't exist.
Class TQGetClass(const char *name);
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
// NSGetSizeAndAlignment augmented to handle extended lambda notation <@>
const char *TQGetSizeAndAlignment(const char *typePtr, NSUInteger *sizep, NSUInteger *alignp);
// Iterates the types in an encoding string by calling the passed block with each
void TQIterateTypesInEncoding(const char *typePtr, TQTypeIterationBlock blk);

// Returns the number of arguments a tranquil block takes (If the object is not a block originating from tranquil, it returns -1)
NSInteger TQBlockGetNumberOfArguments(id block);

// These functions manage the non-local return propagation stack
int TQShouldPropagateNonLocalReturn(id block);
void *TQGetNonLocalReturnJumpTarget(pthread_t thread, id destBlock, int dest, id retVal);
void *TQGetNonLocalReturnPropagationJumpTarget();
void *TQPushNonLocalReturnStack(id block);
void TQPopNonLocalReturnStack();
void *TQPopNonLocalReturnStackAndGetPropagationJumpTarget();
int TQNonLocalReturnStackHeight();
id TQGetNonLocalReturnValue();

void TQInitializeRuntime(int argc, char **argv);

#ifdef __cplusplus
}
#endif
