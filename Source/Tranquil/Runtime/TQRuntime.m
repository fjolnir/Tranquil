#import "TQRuntime.h"
#import "TQBoxedObject.h"
#import "OFString+TQAdditions.h"
#import <ObjFW/ObjFW.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "TQNumber.h"
#import "TQValidObject.h"
#import "TQNothingness.h"
#import "OFObject+TQAdditions.h"
#import "../Shared/khash.h"
#import <pthread.h>
#import <setjmp.h>
#import <ctype.h>

#ifdef __cplusplus
extern "C" {
#endif

id TQValid   = nil;
id TQNothing = nil;

// A hash keyed with `Class xor (Selector << 32)` with values either being 0x1 (No boxing required for selector)
// or a pointer the Method object of the method to be boxed. This is only used by tq_msgSend and tq_boxedMsgSend
//CFMutableDictionaryRef _TQSelectorCache = NULL;

#ifdef __LP64__
#define kh_uintptr_hash_func(key) kh_int64_hash_func(key)
#else
#define kh_uintptr_hash_func(key) kh_int_hash_func(key)
#endif
#define kh_uintptr_hash_equal(a, b) (a == b)

KHASH_INIT(TQSelectorCache, uintptr_t, uintptr_t, 1, kh_uintptr_hash_func, kh_uintptr_hash_equal);
khash_t(TQSelectorCache) *_TQSelectorCache = NULL;

static const OFString *_TQDynamicIvarTableKey = @"TQDynamicIvarTableKey";

static pthread_key_t _TQNonLocalReturnStackKey;

struct _TQNonLocalReturnStack {
    int height, capacity;
    struct _TQNonLocalReturnStackFrame { jmp_buf jumpBuf; id block; } *items;
    int propagateTo;
    id  value;
    pthread_t thread;
};

SEL TQEqOpSel;
SEL TQNeqOpSel;
SEL TQLTOpSel;
SEL TQGTOpSel;
SEL TQGTEOpSel;
SEL TQLTEOpSel;
SEL TQMultOpSel;
SEL TQDivOpSel;
SEL TQModOpSel;
SEL TQAddOpSel;
SEL TQSubOpSel;
SEL TQUnaryMinusOpSel;
SEL TQLShiftOpSel;
SEL TQRShiftOpSel;
SEL TQConcatOpSel;
SEL TQSetterOpSel;
SEL TQGetterOpSel;
SEL TQExpOpSel;

SEL TQNumberWithDoubleSel;
SEL TQStringWithUTF8StringSel;
SEL TQStringWithFormatSel;
SEL TQPointerArrayWithObjectsSel;
SEL TQMapWithObjectsAndKeysSel;
SEL TQRegexWithPatSel;
SEL TQMoveToHeapSel;
SEL TQWeakSel;
SEL TQPromiseSel;

Class TQNumberClass;

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

void _TQCacheSelector(id obj, SEL sel)
{
    @synchronized((id)_TQSelectorCache) {
        Class kls = object_getClass(obj);
        // See msgsend.s for an explanation of the key
#ifdef __LP64__
        uintptr_t cacheKey = (uintptr_t)kls ^ ((uintptr_t)sel << 32);
#else
        uintptr_t cacheKey = (uintptr_t)kls ^ ((uintptr_t)sel << 16); // TODO: verify if this works
#endif

        Method method = class_getInstanceMethod(kls, sel);
        // Methods that do not have a registered implementation are assumed to take&return only objects
        uintptr_t val = 0x1L; // 0x1L => unboxed
        if(method && TQMethodTypeRequiresBoxing(method_getTypeEncoding(method))) {
            val = (uintptr_t)method;
        }

        int err;
        khiter_t cur = kh_put(TQSelectorCache, _TQSelectorCache, cacheKey, &err);
        if(err) {
            kh_del(TQSelectorCache, _TQSelectorCache, cacheKey);
            return;
        }
        kh_value(_TQSelectorCache, cur) = val;
    }
}

uintptr_t _TQSelectorCacheLookup(uintptr_t key) {
    khiter_t k = kh_get(TQSelectorCache, _TQSelectorCache, key);
    return kh_exist(_TQSelectorCache, k) ? kh_value(_TQSelectorCache, k) : 0;
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

// TODO: Rewrite NSGetSizeAndAlignment!
extern const char *NSGetSizeAndAlignment(const char *typePtr, unsigned long *sizep, unsigned long *alignp);
const char *TQGetSizeAndAlignment(const char *typePtr, unsigned long *sizep, unsigned long *alignp)
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
    unsigned long size, align;
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

long TQBlockGetNumberOfArguments(id block)
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

static inline OFMutableDictionary *_TQGetDynamicIvarTable(id obj)
{
    OFMutableDictionary *ivarTable = objc_getAssociatedObject(obj, _TQDynamicIvarTableKey);
    if(!ivarTable) {
        ivarTable = [OFMutableDictionary new];
        objc_setAssociatedObject(obj, _TQDynamicIvarTableKey, ivarTable, OBJC_ASSOCIATION_RETAIN);
        [ivarTable release];
    }
    return ivarTable;
}

OFMutableDictionary *TQGetDynamicIvarTable(id obj)
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

id TQValueForKey(id obj, OFString *key)
{
    assert(key);
    if(!obj)
        return nil;

    Class kls = object_getClass(obj);
    SEL selector = sel_registerName([key UTF8String]);
    if(class_respondsToSelector(kls, selector))
        return tq_msgSend(obj, selector);

    return [_TQGetDynamicIvarTable(obj) objectForKey:key];
}

void TQSetValueForKey(id obj, OFString *key, id value)
{
    assert(key);
    if(!obj)
        return;
    if(TQObjectIsStackBlock(value))
        value = [[value copy] autorelease];

    Class kls = object_getClass(obj);
    OFString *selStr = [OFString stringWithFormat:@"set%@:", [key stringByCapitalizingFirstLetter]];
    SEL setterSel = sel_registerName([selStr UTF8String]);
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

OFArray *TQVaargsToArray(va_list *items)
{
    register id arg;
    OFMutableArray *arr = [OFMutableArray new];
    while((arg = va_arg(*items, id)) != TQNothing) {
        [arr addObject:arg];
    }
    [arr makeImmutable];
    return [arr autorelease];
}

OFArray *TQCliArgsToArray(int argc, char **argv)
{
    OFMutableArray *arr = [OFMutableArray new];
    if(argc <= 1)
        return arr;
    for(int i = 1; i < argc; ++i) {
        [arr addObject:(void *)[OFMutableString stringWithUTF8String:argv[i]]];
    }
    [arr makeImmutable];
    return [arr autorelease];
}

#pragma mark - Operators

BOOL TQAugmentClassWithOperators(Class klass)
{
    // ==
    IMP imp = imp_implementationWithBlock(^(id a, id b) { return [a isEqual:b] ? TQValid : nil; });
    class_addMethod(klass, TQEqOpSel, imp, "@@:@");
    // !=
    imp = imp_implementationWithBlock(^(id a, id b)     { return [a isEqual:b] ? nil : TQValid; });
    class_addMethod(klass, TQNeqOpSel, imp, "@@:@");

    // + (Unimplemented by default)
    imp = imp_implementationWithBlock(^(id a, id b) { return _objc_msgSend_hack2(a, @selector(add:), b); });
    class_addMethod(klass, TQAddOpSel, imp, "@@:@");
    // - (Unimplemented by default)
    imp = imp_implementationWithBlock(^(id a, id b) { return _objc_msgSend_hack2(a, @selector(subtract:), b); });
    class_addMethod(klass, TQSubOpSel, imp, "@@:@");
    // unary - (Unimplemented by default)
    imp = imp_implementationWithBlock(^(id a)       { return _objc_msgSend_hack(a, @selector(negate)); });
    class_addMethod(klass, TQUnaryMinusOpSel, imp, "@@:");

    // * (Unimplemented by default)
    imp = imp_implementationWithBlock(^(id a, id b) { return _objc_msgSend_hack2(a, @selector(multiply:), b); });
    class_addMethod(klass, TQMultOpSel, imp, "@@:@");
    // / (Unimplemented by default)
    imp = imp_implementationWithBlock(^(id a, id b) { return  _objc_msgSend_hack2(a, @selector(divideBy:), b); });
    class_addMethod(klass, TQDivOpSel, imp, "@@:@");

    // ^ (Unimplemented by default)
    imp = imp_implementationWithBlock(^(id a, id b) { return  _objc_msgSend_hack2(a, @selector(pow:), b); });
    class_addMethod(klass, TQExpOpSel, imp, "@@:@");

    // <
    imp = imp_implementationWithBlock(^(id a, id b) { return ([a compare:b] == OF_ORDERED_ASCENDING) ? TQValid : nil; });
    class_addMethod(klass, TQLTOpSel, imp, "@@:@");
    // >
    imp = imp_implementationWithBlock(^(id a, id b) { return ([a compare:b] == OF_ORDERED_DESCENDING) ? TQValid : nil; });
    class_addMethod(klass, TQGTOpSel, imp, "@@:@");
    // <=
    imp = imp_implementationWithBlock(^(id a, id b) { return ([a compare:b] != OF_ORDERED_DESCENDING) ? TQValid : nil; });
    class_addMethod(klass, TQLTEOpSel, imp, "@@:@");
    // >=
    imp = imp_implementationWithBlock(^(id a, id b) { return ([a compare:b] != OF_ORDERED_ASCENDING) ? TQValid : nil; });
    class_addMethod(klass, TQGTEOpSel, imp, "@@:@");


    // []
    imp = imp_implementationWithBlock(^(id a, id key)         { return _objc_msgSend_hack2(a, @selector(objectForKeyedSubscript:), key); });
    class_addMethod(klass, TQGetterOpSel, imp, "@@:@");
    // []=
    imp = imp_implementationWithBlock(^(id a, id key, id val) { return _objc_msgSend_hack3(a, @selector(setObject:forKeyedSubscript:), val, key); });
    class_addMethod(klass, TQSetterOpSel, imp, "@@:@@");

    return YES;
}
#if TARGET_OS_EMBEDDED
#error "YEAH"
#endif
void TQInitializeRuntime()
{
    if(_TQSelectorCache)
        return;

    _TQSelectorCache = kh_init(TQSelectorCache);
//    _TQSelectorCache = CFDictionaryCreateMutable(NULL, 1000, NULL, NULL);
//                                        (NSMapTableValueCallBacks){NULL,NULL,NULL}, 1000);
//    _TQSelectorCache = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsOpaqueMemory
//                                                 valueOptions:NSPointerFunctionsOpaqueMemory
//                                                     capacity:1000];

    pthread_key_create(&_TQNonLocalReturnStackKey, (void (*)(void *))&_destroyNonLocalReturnStack);

    TQValid   = [TQValidObject valid];
    TQNothing = [TQNothingness nothing];

    TQEqOpSel                    = sel_registerName("==:");
    TQNeqOpSel                   = sel_registerName("!=:");
    TQAddOpSel                   = sel_registerName("+:");
    TQSubOpSel                   = sel_registerName("-:");
    TQUnaryMinusOpSel            = sel_registerName("-");
    TQMultOpSel                  = sel_registerName("*:");
    TQDivOpSel                   = sel_registerName("/:");
    TQModOpSel                   = sel_registerName("%:");
    TQLTOpSel                    = sel_registerName("<:");
    TQGTOpSel                    = sel_registerName(">:");
    TQLTEOpSel                   = sel_registerName("<=:");
    TQGTEOpSel                   = sel_registerName(">=:");
    TQLShiftOpSel                = sel_registerName("<<:");
    TQRShiftOpSel                = sel_registerName(">>:");
    TQConcatOpSel                = sel_registerName("..:");
    TQGetterOpSel                = sel_registerName("[]:");
    TQSetterOpSel                = sel_registerName("[]:=:");
    TQExpOpSel                   = sel_registerName("^:");

    TQNumberWithDoubleSel        = @selector(numberWithDouble:);
    TQStringWithUTF8StringSel    = @selector(stringWithUTF8String:);
    TQStringWithFormatSel        = @selector(stringWithFormat:);
    TQPointerArrayWithObjectsSel = @selector(tq_pointerArrayWithObjects:);
    TQMapWithObjectsAndKeysSel   = @selector(tq_mapTableWithObjectsAndKeys:);
    TQRegexWithPatSel            = @selector(tq_regularExpressionWithPattern:options:);
    TQMoveToHeapSel              = @selector(moveValueToHeap);
    TQWeakSel                    = @selector(with:);
    TQPromiseSel                 = @selector(promise);

    TQNumberClass     = [TQNumber class];

    // Add operators that cannot be added through standard categories (because the compiler won't allow methods containing symbols)
    TQAugmentClassWithOperators([OFObject class]);
	Class nsObjKls = objc_getClass("NSObject");
	if(nsObjKls)
		TQAugmentClassWithOperators(nsObjKls);

    IMP imp;
    // Operators for OFString
    imp = imp_implementationWithBlock(^(id a, TQNumber *idx)   {
        return [a substringWithRange:(of_range_t){[idx intValue], 1}];
    });
    class_addMethod([OFString class], TQGetterOpSel, imp, "@@:@");

    imp = imp_implementationWithBlock(^(id a, TQNumber *idx, OFString *replacement)   {
        int loc = [idx intValue];
        [a deleteCharactersInRange:(of_range_t){loc, 1}];
        [a insertString:replacement atIndex:loc];
        return a;
    });
    class_addMethod([OFMutableString class], TQSetterOpSel, imp, "@@:@");


    // Operators for collections
    imp = imp_implementationWithBlock(^(id a, id key)         { return _objc_msgSend_hack2(a, @selector(objectForKeyedSubscript:), key); });
    class_addMethod([OFDictionary class], TQGetterOpSel, imp, "@@:@");

    imp = imp_implementationWithBlock(^(id a, TQNumber *idx)   {
        return _objc_msgSend_hack2i(a, @selector(objectAtIndexedSubscript:), [idx unsignedIntegerValue]);
    });
    class_addMethod([OFArray class], TQGetterOpSel, imp, "@@:@");

    // []=
    imp = imp_implementationWithBlock(^(id a, id key, id val) {
        return _objc_msgSend_hack3(a, @selector(setObject:forKeyedSubscript:), val, key);
    });
    class_addMethod([OFMutableDictionary class], TQSetterOpSel, imp, "@@:@@");

    imp = imp_implementationWithBlock(^(id a, TQNumber *idx, id val)   {
        return _objc_msgSend_hack3i(a, @selector(setObject:atIndexedSubscript:), val, [idx unsignedIntegerValue]);
    });
    class_addMethod([OFMutableArray class], TQSetterOpSel, imp, "@@:@");

    // <<&>>
    imp = class_getMethodImplementation([OFMutableArray class], @selector(addObject:));
    class_addMethod([OFMutableArray class], TQLShiftOpSel, imp, "@@:@");
    imp = imp_implementationWithBlock(^(id a, id b)   {
        _objc_msgSend_hack3i(a, @selector(insertObject:atIndex:), b, 0);
        return a;
    });
    class_addMethod([OFMutableArray class], TQRShiftOpSel, imp, "@@:@");

    // Operators for OF(Mutable)String
    imp = imp_implementationWithBlock(^(id a, id b)   {
         id ret = _objc_msgSend_hack2(a, @selector(stringByAppendingString:), [b toString]);
         return _objc_msgSend_hack2([OFMutableString class], @selector(stringWithString:), ret);
    });
    class_addMethod([OFString class], TQConcatOpSel, imp, "@@:@");
    imp = imp_implementationWithBlock(^(id a, id b)   {
         _objc_msgSend_hack2(a, @selector(appendString:), [b toString]);
         return a;
    });
    class_addMethod([OFMutableString class], TQLShiftOpSel, imp, "@@:@");
    imp = imp_implementationWithBlock(^(id a, id b)   {
        _objc_msgSend_hack3i(a, @selector(insertString:atIndex:), [b toString], 0);
        return a;
    });
    class_addMethod([OFMutableString class], TQRShiftOpSel, imp, "@@:@");
}

#ifdef __cplusplus
}
#endif
