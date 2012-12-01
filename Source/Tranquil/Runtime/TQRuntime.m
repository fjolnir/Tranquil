#import "TQRuntime.h"
#import "TQBoxedObject.h"
#import "NSString+TQAdditions.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "TQNumber.h"
#import "TQValidObject.h"
#import "TQNothingness.h"
#import "NSObject+TQAdditions.h"
#import "../Shared/khash.h"
#import <pthread.h>
#import <setjmp.h>
#import <ctype.h>

#ifdef __cplusplus
extern "C" {
#endif

id TQValid   = nil;
id TQNothing = nil;

// A map keyed with `Class xor (Selector << 32)` with values either being 0x1 (No boxing required for selector)
// or a pointer the Method object of the method to be boxed. This is only used by tq_msgSend and tq_boxedMsgSend
//CFMutableDictionaryRef _TQSelectorCache = NULL;

#ifdef __LP64__
#define kh_uintptr_hash_func(key) kh_int64_hash_func(key)
#else
#define kh_uintptr_hash_func(key) kh_int_hash_func(key)
#endif
#define kh_uintptr_hash_equal(a, b) (a == b)

KHASH_INIT(selectorCache, uintptr_t, uintptr_t, 1, kh_uintptr_hash_func, kh_uintptr_hash_equal);
khash_t(selectorCache) *_TQSelectorCache = NULL;

static const NSString *_TQDynamicIvarTableKey = @"TQDynamicIvarTableKey";

static pthread_key_t _TQNonLocalReturnStackKey;

struct _TQNonLocalReturnStack {
    int height, capacity;
    struct _TQNonLocalReturnStackFrame { jmp_buf jumpBuf; id block; } *items;
    int propagateTo;
    id  value;
    pthread_t thread;
};

dispatch_queue_t TQGlobalQueue;

struct TQBlockByRef TQGlobalVar_TQArguments = {
    nil, &TQGlobalVar_TQArguments, 0, sizeof(struct TQBlockByRef), nil
};

struct TQBlock_byref {
    void *isa;
    struct TQBlock_byref *forwarding;
    int flags;
    int size;
    void (*byref_keep)(struct TQBlock_byref *dst, struct TQBlock_byref *src);
    void (*byref_destroy)(struct TQBlock_byref *);
    id capture;
};

#pragma mark - Utilities

// Hack from libobjc, allows tail call optimization for objc_msgSend
extern id _objc_msgSend_hack(id, SEL)            asm("_objc_msgSend");
extern id _objc_msgSend_hack2(id, SEL, id)       asm("_objc_msgSend");
extern id _objc_msgSend_hack3(id, SEL, id, id)   asm("_objc_msgSend");
extern id _objc_msgSend_hack2i(id, SEL, int)     asm("_objc_msgSend");
extern id _objc_msgSend_hack3i(id, SEL, id, int) asm("_objc_msgSend");

#pragma mark -
Class TQGetOrCreateClass(const char *name, const char *superName)
{
    Class klass = objc_getClass(name);
    if(klass)
        return klass;
    Class superKlass = objc_getClass(superName);
    assert(superKlass != nil);
    klass = objc_allocateClassPair(superKlass, name, 0);
    assert(klass != nil);
    objc_registerClassPair(klass);

    return klass;
}

Class TQGetClass(const char *name)
{
    Class kls = objc_getClass(name);
    TQAssert(kls, @"Class '%s' does not exist", name);
    return kls;
}

Class TQObjectGetSuperClass(id aObj)
{
    return class_getSuperclass(object_getClass(aObj));
}

BOOL TQMethodTypeRequiresBoxing(const char *aEncoding)
{
    if(*aEncoding != '@' && *aEncoding != 'v')
        return YES;
    while(*(++aEncoding) != ':') {} // Just iterate till the selector
    // First run of this loop skips over the selector
    while(*(++aEncoding) != '\0') {
        if((*aEncoding != '@' && !isdigit(*aEncoding)) && !(*aEncoding == '?' && *(aEncoding - 1) == '@'))
            return YES;
    }
    return NO;
}

static const uintptr_t _keyShift = sizeof(uintptr_t) / 2;
void _TQCacheSelector(id obj, SEL sel)
{
    @synchronized((id)_TQSelectorCache) {
        Class kls = object_getClass(obj);
        uintptr_t key = (uintptr_t)kls ^ (uintptr_t)sel << _keyShift;

        Method method = class_getInstanceMethod(kls, sel);
        // Methods that do not have a registered implementation are assumed to take&return only objects
        uintptr_t val = 0x1L; // 0x1L => unboxed
        if(method && TQMethodTypeRequiresBoxing(method_getTypeEncoding(method))) {
            val = (uintptr_t)method;
        }

        int ret;
        khiter_t cur = kh_put_selectorCache(_TQSelectorCache, key, &ret);
        if(!ret) kh_del_selectorCache(_TQSelectorCache, key);

        kh_value(_TQSelectorCache, cur) = val;
    }
}

uintptr_t _TQSelectorCacheLookup(id obj, SEL sel) {
    Class kls = object_getClass(obj);
    uintptr_t key = (uintptr_t)kls ^ (uintptr_t)sel << _keyShift;

    khiter_t k = kh_get_selectorCache(_TQSelectorCache, key);
    return ((k != kh_end(_TQSelectorCache)) && kh_exist(_TQSelectorCache, k)) ? kh_value(_TQSelectorCache, k) : 0;
}

void TQUnboxObject(id object, const char *type, void *buffer)
{
    if(*type == _C_ID)
        *(id*)buffer = object;
    else
        [TQBoxedObject unbox:object to:buffer usingType:type];
}

id TQBoxValue(void *value, const char *type)
{
    return [TQBoxedObject box:value withType:type];
}

int64_t _TQObjectToNanoseconds(id obj)
{
    double seconds = [obj doubleValue];
    return (int64_t)(seconds * 1000000000.0);
}

// TODO: This turns out to not actually be sufficient, there are additional cases to be handled for structs composed of smaller types (on x86-64)
BOOL TQStructSizeRequiresStret(int size)
{
    #if defined(__LP64__)
        return size > sizeof(long)*2;
    #elif defined(__arm__)
        return YES; // All structs are stret returned on arm
    #else
        return size > sizeof(long);
    #endif
}

const char *TQGetSizeAndAlignment(const char *typePtr, NSUInteger *sizep, NSUInteger *alignp)
{
    if(*typePtr == _TQ_C_LAMBDA_B) {
        if(sizep)
            *sizep = sizeof(void*);
        if(alignp)
            *alignp = __alignof(id (*)()); // TODO: Make this handle cross compilation
        unsigned depth = 0;
        do {
            if(*typePtr == _TQ_C_LAMBDA_B)
                ++depth;
            else if(*typePtr == _TQ_C_LAMBDA_E)
                --depth;
            ++typePtr;
            if(depth == 0)
                break;
        } while(*typePtr != '\0');
    } else
        typePtr = NSGetSizeAndAlignment(typePtr, sizep, alignp);

    // Get rid of the aligning numbers and qualifiers unused at runtime
    while(isdigit(*typePtr) || *typePtr == _C_CONST) ++typePtr;
    return typePtr;
}

void TQIterateTypesInEncoding(const char *typePtr, TQTypeIterationBlock blk)
{
    assert(blk);
    if(!typePtr || strlen(typePtr) == 0)
        return;
    NSUInteger size, align;
    const char *nextPtr;
    BOOL shouldStop = NO;
    do {
        nextPtr = TQGetSizeAndAlignment(typePtr, &size, &align);
        blk(typePtr, size, align, &shouldStop);
        if(shouldStop)
            break;
        typePtr = nextPtr;
    } while(typePtr && *typePtr != '\0' && *typePtr != _C_STRUCT_E && *typePtr != _TQ_C_LAMBDA_E
            && *typePtr != _C_UNION_E && *typePtr != _C_ARY_E);
}

NSInteger TQBlockGetNumberOfArguments(id block)
{
    struct TQBlockLiteral *blk = (struct TQBlockLiteral *)block;
    if(blk->flags & TQ_BLOCK_IS_TRANQUIL_BLOCK)
        return blk->descriptor->numArgs;
    return -1;
}

#pragma mark - Non-local returns

static void _destroyNonLocalReturnStack(struct _TQNonLocalReturnStack *stack)
{
    if(stack) {
        free(stack->items);
        free(stack);
    }
}

static __inline__ struct _TQNonLocalReturnStack *_getNonLocalReturnStack()
{
    struct _TQNonLocalReturnStack *stack = pthread_getspecific(_TQNonLocalReturnStackKey);
    if(!stack) {
        stack = calloc(1, sizeof(struct _TQNonLocalReturnStack));
        stack->capacity = 128;
        stack->thread   = pthread_self();
        stack->items    = malloc(stack->capacity * sizeof(struct _TQNonLocalReturnStackFrame));
        pthread_setspecific(_TQNonLocalReturnStackKey, stack);
    }
    return stack;
}

// Pops the stack and returns whether the caller should propagate or not
int TQShouldPropagateNonLocalReturn(id block)
{
    struct _TQNonLocalReturnStack *stack = _getNonLocalReturnStack();
    TQAssert(stack->height > 0, @"PANIC: Tried to propagate non-local return but stack was empty");
    if(stack->height-- != stack->propagateTo) {
        assert(block == stack->items[stack->height].block);
        return YES;
    }
    return NO;
}

// Returns a pointer to pass to longjmp, and sets the destination block to propagate up to
void *TQGetNonLocalReturnJumpTarget(pthread_t thread, id destBlock, int dest, id retVal)
{
    struct _TQNonLocalReturnStack *stack = _getNonLocalReturnStack();
    TQAssert(pthread_equal(thread, stack->thread) != 0, @"Tried to perform non-local return from a different thread");
    TQAssert(stack->height >= dest && stack->height > 0, @"Tried to perform non-local return outside parent scope");
    TQAssert(stack->items[dest-1].block == destBlock, @"Tried to perform non-local return outside parent scope");

    stack->propagateTo = dest;
    stack->value = retVal;
    return stack->items[stack->height-1].jumpBuf;
}

// Returns a pointer to pass to longjmp
void *TQGetNonLocalReturnPropagationJumpTarget()
{
    struct _TQNonLocalReturnStack *stack = _getNonLocalReturnStack();
    TQAssert(stack->height > 0, @"PANIC: Tried to propagate non-local return but stack was empty");
    return stack->items[stack->height-1].jumpBuf;
}
// Pops the stack and returns the non local return target left on the top to pass to longjmp
void *TQPopNonLocalReturnStackAndGetPropagationJumpTarget()
{
    struct _TQNonLocalReturnStack *stack = _getNonLocalReturnStack();
    --stack->height;
    TQAssert(stack->height > 0, @"PANIC: Tried to propagate non-local return but stack was empty");
    return stack->items[stack->height-1].jumpBuf;
}

// Returns a pointer to pass to setjmp
void *TQPushNonLocalReturnStack(id block)
{
    struct _TQNonLocalReturnStack *stack = _getNonLocalReturnStack();
    int idx = stack->height;
    if(++stack->height > stack->capacity) {
        stack->capacity <<= 1;
        stack->items = realloc(stack->items, stack->capacity * sizeof(struct _TQNonLocalReturnStackFrame));
        assert(stack->items);
    }
    stack->items[idx].block = block;
    return stack->items[idx].jumpBuf;
}
// Just pops the stack (for use when the block returns normally)
void TQPopNonLocalReturnStack()
{
    struct _TQNonLocalReturnStack *stack = _getNonLocalReturnStack();
    TQAssert(stack->height > 0, @"PANIC: Tried to pop non-local return but stack was empty");
    --stack->height;
}

int TQNonLocalReturnStackHeight()
{
    return _getNonLocalReturnStack()->height;
}

id TQGetNonLocalReturnValue()
{
    return _getNonLocalReturnStack()->value;
}


#pragma mark - Dynamic instance variables

static inline NSMutableDictionary *_TQGetDynamicIvarTable(id obj)
{
    NSMutableDictionary *ivarTable = objc_getAssociatedObject(obj, _TQDynamicIvarTableKey);
    if(!ivarTable) {
        ivarTable = [NSMutableDictionary new];
        objc_setAssociatedObject(obj, _TQDynamicIvarTableKey, ivarTable, OBJC_ASSOCIATION_RETAIN);
        [ivarTable release];
    }
    return ivarTable;
}

NSMutableDictionary *TQGetDynamicIvarTable(id obj)
{
    return _TQGetDynamicIvarTable(obj);
}

static inline size_t _accessorNameLen(const char *accessorNameLoc)
{
    const char *accessorNameEnd = strstr(accessorNameLoc, ",");
    if(!accessorNameEnd)
        return strlen(accessorNameLoc);
    else
        return accessorNameEnd - accessorNameLoc;
}

id TQValueForKey(id obj, NSString *key)
{
    assert(key);
    if(!obj)
        return nil;

    Class kls = object_getClass(obj);
    SEL selector = NSSelectorFromString(key);
    if(class_respondsToSelector(kls, selector))
        return tq_msgSend(obj, selector);

    return [_TQGetDynamicIvarTable(obj) objectForKey:key];
}

void TQSetValueForKey(id obj, NSString *key, id value)
{
    assert(key);
    if(!obj)
        return;
    if(TQObjectIsStackBlock(value))
        value = [[value copy] autorelease];

    Class kls = object_getClass(obj);
    NSString *selStr = [NSString stringWithFormat:@"set%@:", [key stringByCapitalizingFirstLetter]];
    SEL setterSel = NSSelectorFromString(selStr);
    if(class_respondsToSelector(kls, setterSel))
        tq_msgSend(obj, setterSel, value);


    if(value)
        [_TQGetDynamicIvarTable(obj) setObject:value forKey:key];
    else
        [_TQGetDynamicIvarTable(obj) removeObjectForKey:key];
}

#pragma mark -

BOOL TQObjectIsStackBlock(id obj)
{
    return object_getClass(obj) == (Class)_NSConcreteStackBlock;
}

id TQPrepareObjectForReturn(id obj)
{
    if(TQObjectIsStackBlock(obj))
        return _objc_msgSend_hack(obj, @selector(copy));
    return objc_retain(obj);
}

void TQStoreStrong(id *location, id obj)
{
    if(TQObjectIsStackBlock(obj)) {
        id prev = *location;
        *location = _objc_msgSend_hack(obj, @selector(copy));
        objc_release(prev);
    } else
        objc_storeStrong(location, obj);
}

extern void _Block_object_assign(void *destAddr, const void *object, const int flags);
void _TQ_Block_object_assign(struct TQBlockByRef **dest, struct TQBlockByRef *src, const int flags)
{
    id value;
    switch(flags) {
        case TQ_BLOCK_FIELD_IS_BYREF:
            value = src->forwarding->value;
            if(TQObjectIsStackBlock(value))
                src->forwarding->value = _objc_msgSend_hack(value, @selector(copy));
            objc_retain(src->forwarding->value);
        break;
        case TQ_BLOCK_FIELD_IS_OBJECT:
            objc_retain((id)src);
        break;
    }
    _Block_object_assign((void *)dest, (void *)src, flags);
}
NSPointerArray *TQVaargsToArray(va_list *items)
{
    register id arg;
    NSPointerArray *arr = [NSPointerArray new];
    while((arg = va_arg(*items, id)) != TQNothing) {
        [arr addPointer:arg];
    }
    return [arr autorelease];
}

void TQInitializeRuntime(int argc, char **argv)
{
    if(argc > 0) {
        NSPointerArray *args = [NSPointerArray new];
        for(int i = 1; i < argc; ++i) {
            [args addPointer:(void *)[NSMutableString stringWithUTF8String:argv[i]]];
        }
        TQGlobalVar_TQArguments.forwarding->value = args;
    }
    if(_TQSelectorCache)
        return;

    TQGlobalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT , 0);

    _TQSelectorCache = kh_init_selectorCache();

    pthread_key_create(&_TQNonLocalReturnStackKey, (void (*)(void *))&_destroyNonLocalReturnStack);

    TQValid   = [TQValidObject valid];
    TQNothing = [TQNothingness nothing];
}

#ifdef __cplusplus
}
#endif
