#import "TQRuntime.h"
#import "TQBoxedObject.h"
#import "NSString+TQAdditions.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "TQNumber.h"
#import "NSObject+TQAdditions.h"

#ifdef __cplusplus
extern "C" {
#endif

id TQSentinel = @"3d2c9ac0bf3911e1afa70800200c9a66aaaaaaaaa";
TQValidObject *TQValid = nil;

// A dictionary keyed with `Class xor Selector` with values either being 0x1 (No boxing required for selector)
// or a pointer the Method object of the method to be boxed. This is only used by tq_msgSend and tq_boxedMsgSend
CFMutableDictionaryRef _TQSelectorCache = NULL;

static const NSString *_TQDynamicIvarTableKey = @"TQDynamicIvarTableKey";

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
    @synchronized((NSDictionary *)_TQSelectorCache) {
        Class kls = object_getClass(obj);
        void *cacheKey = (void*)((uintptr_t)kls ^ (uintptr_t)sel);

        Method method = class_getInstanceMethod(kls, sel);
        // Methods that do not have a registered implementation are assumed to take&return only objects
        uintptr_t unboxedVal = 0x1L;
        if(!method) {
            CFDictionarySetValue(_TQSelectorCache, cacheKey, (void*)0x1);
            return;
        }

        const char *enc = method_getTypeEncoding(method);
        if(TQMethodTypeRequiresBoxing(enc))
            CFDictionarySetValue(_TQSelectorCache, cacheKey, (void*)method);
        else
            CFDictionarySetValue(_TQSelectorCache, cacheKey, (void*)0x1);
    }
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

// We either must use these functions to test nil for equality, or use the private _objc_setNilResponder which I don't feel good doing
// For non equality test operators testing against nil is simply always false so we do not need to implement equivalents for them.
id TQObjectsAreEqual(id a, id b)
{
    if(a)
        return _objc_msgSend_hack2(a, TQEqOpSel, b);
    return b == nil ? TQValid : nil;
}

id TQObjectsAreNotEqual(id a, id b)
{
    if(a)
        return _objc_msgSend_hack2(a, TQNeqOpSel, b);
    return b != nil ? TQValid : nil;
}


#pragma mark - Dynamic instance variables

static inline NSMapTable *_TQGetDynamicIvarTable(id obj)
{
    NSMapTable *ivarTable = objc_getAssociatedObject(obj, _TQDynamicIvarTableKey);
    if(!ivarTable) {
        ivarTable = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
        objc_setAssociatedObject(obj, _TQDynamicIvarTableKey, ivarTable, OBJC_ASSOCIATION_RETAIN);
    }
    return ivarTable;
}

NSMapTable *TQGetDynamicIvarTable(id obj)
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
    if(!obj)
        return nil;

    Class kls = object_getClass(obj);
    SEL selector = NSSelectorFromString(key);
    if(class_respondsToSelector(kls, selector))
        return tq_msgSend(obj, selector);

    NSMapTable *ivarTable = _TQGetDynamicIvarTable(obj);
    return (id)NSMapGet(ivarTable, key);
}

void TQSetValueForKey(id obj, NSString *key, id value)
{
    if(!obj)
        return;
    if(TQObjectIsStackBlock(value))
        value = [[value copy] autorelease];

    Class kls = object_getClass(obj);
    NSString *selStr = [NSString stringWithFormat:@"set%@:", [key stringByCapitalizingFirstLetter]];
    SEL setterSel = NSSelectorFromString(selStr);
    if(class_respondsToSelector(kls, setterSel))
        tq_msgSend(obj, setterSel, value);

    NSMapTable *ivarTable = _TQGetDynamicIvarTable(obj);
    if(value)
        NSMapInsert(ivarTable, key, value);
    else
        NSMapRemove(ivarTable, key);
}

#pragma mark -

BOOL TQObjectIsStackBlock(id obj)
{
    return obj != nil && object_getClass(obj) == (Class)_NSConcreteStackBlock;
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

NSPointerArray *TQVaargsToArray(va_list *items)
{
    register id arg;
    NSPointerArray *arr = [NSPointerArray pointerArrayWithWeakObjects];
    while((arg = va_arg(*items, id)) != TQSentinel) {
        [arr addPointer:arg];
    }
    return arr;
}

NSPointerArray *TQCliArgsToArray(int argc, char **argv)
{
    NSPointerArray *arr = [NSPointerArray pointerArrayWithStrongObjects];
    if(argc <= 1)
        return arr;
    for(int i = 1; i < argc; ++i) {
        [arr addPointer:(void *)[NSMutableString stringWithUTF8String:argv[i]]];
    }
    return arr;
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

    // <
    imp = imp_implementationWithBlock(^(id a, id b) { return ([a compare:b] == NSOrderedAscending) ? TQValid : nil; });
    class_addMethod(klass, TQLTOpSel, imp, "@@:@");
    // >
    imp = imp_implementationWithBlock(^(id a, id b) { return ([a compare:b] == NSOrderedDescending) ? TQValid : nil; });
    class_addMethod(klass, TQGTOpSel, imp, "@@:@");
    // <=
    imp = imp_implementationWithBlock(^(id a, id b) { return ([a compare:b] != NSOrderedDescending) ? TQValid : nil; });
    class_addMethod(klass, TQLTEOpSel, imp, "@@:@");
    // >=
    imp = imp_implementationWithBlock(^(id a, id b) { return ([a compare:b] != NSOrderedAscending) ? TQValid : nil; });
    class_addMethod(klass, TQGTEOpSel, imp, "@@:@");


    // []
    imp = imp_implementationWithBlock(^(id a, id key)         { return _objc_msgSend_hack2(a, @selector(valueForKey:), key); });
    class_addMethod(klass, TQGetterOpSel, imp, "@@:@");
    // []=
    imp = imp_implementationWithBlock(^(id a, id key, id val) { return _objc_msgSend_hack3(a, @selector(setValue:forKey:), val, key); });
    class_addMethod(klass, TQSetterOpSel, imp, "@@:@@");

    return YES;
}

void TQInitializeRuntime()
{
    if(_TQSelectorCache)
        return;

    _TQSelectorCache = CFDictionaryCreateMutable(NULL, 100, NULL, NULL);

    TQValid = [TQValidObject sharedInstance];

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

    TQNumberClass     = [TQNumber class];

    // Add operators that cannot be added through standard categories (because the compiler won't allow methods containing symbols)
    TQAugmentClassWithOperators([NSObject class]);

    IMP imp;
    // Operators for NSString
    imp = imp_implementationWithBlock(^(id a, TQNumber *idx)   {
        return [a substringWithRange:(NSRange){[idx intValue], 1}];
    });
    class_addMethod([NSString class], TQGetterOpSel, imp, "@@:@");

    imp = imp_implementationWithBlock(^(id a, TQNumber *idx, NSString *replacement)   {
        int loc = [idx intValue];
        [a deleteCharactersInRange:(NSRange){loc, 1}];
        [a insertString:replacement atIndex:loc];
        return a;
    });
    class_addMethod([NSMutableString class], TQSetterOpSel, imp, "@@:@");


    // Operators for collections
    imp = imp_implementationWithBlock(^(id a, id key)         { return _objc_msgSend_hack2(a, @selector(objectForKeyedSubscript:), key); });
    class_addMethod([NSDictionary class], TQGetterOpSel, imp, "@@:@");
    class_addMethod([NSMapTable class], TQGetterOpSel, imp, "@@:@");

    imp = imp_implementationWithBlock(^(id a, TQNumber *idx)   {
        return _objc_msgSend_hack2i(a, @selector(objectAtIndexedSubscript:), [idx unsignedIntegerValue]);
    });
    class_addMethod([NSArray class], TQGetterOpSel, imp, "@@:@");
    class_addMethod([NSPointerArray class], TQGetterOpSel, imp, "@@:@");

    // []=
    imp = imp_implementationWithBlock(^(id a, id key, id val) {
        return _objc_msgSend_hack3(a, @selector(setObject:forKeyedSubscript:), val, key);
    });
    class_addMethod([NSMutableDictionary class], TQSetterOpSel, imp, "@@:@@");
    class_addMethod([NSMapTable class], TQSetterOpSel, imp, "@@:@@");

    imp = imp_implementationWithBlock(^(id a, TQNumber *idx, id val)   {
        return _objc_msgSend_hack3i(a, @selector(setObject:atIndexedSubscript:), val, [idx unsignedIntegerValue]);
    });
    class_addMethod([NSMutableArray class], TQSetterOpSel, imp, "@@:@");
    class_addMethod([NSPointerArray class], TQSetterOpSel, imp, "@@:@");

    // <<&>>
    imp = class_getMethodImplementation([NSPointerArray class], @selector(push:));
    class_addMethod([NSPointerArray class], TQLShiftOpSel, imp, "@@:@");
    imp = imp_implementationWithBlock(^(id a, id b)   {
        _objc_msgSend_hack3i(a, @selector(insertPointer:atIndex:), b, 0);
        return a;
    });
    class_addMethod([NSPointerArray class], TQRShiftOpSel, imp, "@@:@");

    // Operators for NS(Mutable)String
    imp = class_getMethodImplementation([NSString class], @selector(stringByAppendingString:));
    class_addMethod([NSString class], TQConcatOpSel, imp, "@@:@");
    imp = imp_implementationWithBlock(^(id a, id b)   {
         _objc_msgSend_hack2(a, @selector(appendString:), [b toString]);
         return a;
    });
    class_addMethod([NSMutableString class], TQLShiftOpSel, imp, "@@:@");
    imp = imp_implementationWithBlock(^(id a, id b)   {
        _objc_msgSend_hack3i(a, @selector(insertString:atIndex:), [b toString], 0);
        return a;
    });
    class_addMethod([NSMutableString class], TQRShiftOpSel, imp, "@@:@");
}

#ifdef __cplusplus
}
#endif
