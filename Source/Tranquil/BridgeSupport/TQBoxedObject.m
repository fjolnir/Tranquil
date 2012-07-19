#import "TQBoxedObject.h"
#import "bs.h"
#import "TQFFIType.h"
#import "../Runtime/TQRuntime.h"
#import "../Runtime/TQNumber.h"
#import "../TQDebug.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <ffi/ffi.h>

#define TQBoxedObject_PREFIX "TQBoxedObject_"
#define BlockImp imp_implementationWithBlock

// To identify whether a block is a wrapper or not
#define TQ_BLOCK_IS_WRAPPER_BLOCK (1 << 20)

static int _TQRetTypeAssocKey, _TQArgTypesAssocKey, _TQFFIResourcesAssocKey;
static void _freeRelinquishFunction(const void *item, NSUInteger (*size)(const void *item));

// Used to wrap blocks that take or return non-objects
struct TQBoxedBlockLiteral;
struct TQBoxedBlockDescriptor {
    unsigned long int reserved; // NULL
    unsigned long int size;     // sizeof(struct TQBoxedBlockLiteral)
};
struct TQBoxedBlockLiteral {
    void *isa; // _NSConcreteStackBlock
    int flags;
    int reserved;
    void *invoke;
    struct TQBoxedBlockDescriptor *descriptor;
    // The required data to call the boxed function
    void *funPtr;
    const char *type;
    NSInteger argSize;
    ffi_cif *cif;
};

static id __wrapperBlock_invoke(struct TQBoxedBlockLiteral *__blk, ...);

static struct TQBoxedBlockDescriptor boxedBlockDescriptor = {
    0,
    sizeof(struct TQBoxedBlockLiteral),
};

// Boxing imps
static id _box_C_ID_imp(TQBoxedObject *self, SEL _cmd, id *aPtr);
static id _box_C_SEL_imp(TQBoxedObject *self, SEL _cmd, SEL *aPtr);
static id _box_C_VOID_imp(TQBoxedObject *self, SEL _cmd, id *aPtr);
static id _box_C_CHARPTR_imp(TQBoxedObject *self, SEL _cmd, const char *aPtr);
static id _box_C_DBL_imp(TQBoxedObject *self, SEL _cmd, double *aPtr);
static id _box_C_FLT_imp(TQBoxedObject *self, SEL _cmd, float *aPtr);
static id _box_C_INT_imp(TQBoxedObject *self, SEL _cmd, int *aPtr);
static id _box_C_SHT_imp(TQBoxedObject *self, SEL _cmd, short *aPtr);
static id _box_C_CHR_imp(TQBoxedObject *self, SEL _cmd, char *aPtr);
static id _box_C_BOOL_imp(TQBoxedObject *self, SEL _cmd, _Bool *aPtr);
static id _box_C_LNG_imp(TQBoxedObject *self, SEL _cmd, long *aPtr);
static id _box_C_LNG_LNG_imp(TQBoxedObject *self, SEL _cmd, long long *aPtr);
static id _box_C_UINT_imp(TQBoxedObject *self, SEL _cmd, unsigned int *aPtr);
static id _box_C_USHT_imp(TQBoxedObject *self, SEL _cmd, unsigned short *aPtr);
static id _box_C_ULNG_imp(TQBoxedObject *self, SEL _cmd, unsigned long *aPtr);
static id _box_C_ULNG_LNG_imp(TQBoxedObject *self, SEL _cmd, unsigned long long *aPtr);

@interface TQBoxedObject ()
+ (NSString *)_classNameForType:(const char *)aType;
+ (Class)_prepareAggregateWrapper:(const char *)aClassName withType:(const char *)aType;
+ (Class)_prepareScalarWrapper:(const char *)aClassName withType:(const char *)aType;
+ (Class)_prepareLambdaWrapper:(const char *)aClassName withType:(const char *)aType;
+ (NSString *)_getFieldName:(const char **)aType;
+ (const char *)_findEndOfPair:(const char *)aStr start:(char)aStartChar end:(char)aEndChar;
+ (const char *)_skipQualifiers:(const char *)aType;
@end

@implementation TQBoxedObject
@synthesize valuePtr=_ptr;

+ (void)load
{
    if(self != [TQBoxedObject class])
        return;

    TQInitializeRuntime();

    Class TQNumberClass = [TQNumber class];
    Class NSNumberClass = [NSNumber class];

    IMP imp;
    // []
    imp = imp_implementationWithBlock(^(id a, id key) {
        if(*(Class*)key == TQNumberClass || *(Class*)key == NSNumberClass)
            return [a objectAtIndexedSubscript:[(TQNumber *)key intValue]];
        else
            return [a objectForKeyedSubscript:key];
    });
    class_replaceMethod(self, TQGetterOpSel, imp, "@@:@");

    // []=
    imp = imp_implementationWithBlock(^(id a, id key, id val) {
        if(*(Class*)key == TQNumberClass || *(Class*)key == NSNumberClass)
            return [a setObject:val atIndexedSubscript:[(TQNumber *)key intValue]];
        else
            return [a setObject:val forKeyedSubscript:key];
    });
    class_replaceMethod(self, TQSetterOpSel, imp, "@@:@@");

}

+ (id)box:(void *)aPtr withType:(const char *)aType
{
    aType = [self _skipQualifiers:aType];
    // Check if this type has been handled already
    const char *className = [[self _classNameForType:aType] UTF8String];
    Class boxingClass = objc_getClass(className);
    if(boxingClass)
        return [boxingClass box:aPtr];

    // Seems it hasn't. Let's.
    if([self typeIsScalar:aType])
        boxingClass = [self _prepareScalarWrapper:className withType:aType];
    else if(*aType == _C_STRUCT_B || *aType == _C_UNION_B)
        boxingClass = [self _prepareAggregateWrapper:className withType:aType];
    else if(*aType == _MR_C_LAMBDA_B)
        boxingClass = [self _prepareLambdaWrapper:className withType:aType];
    else {
        NSLog(@"Type %s cannot be unboxed", aType);
        return nil;
    }
    objc_registerClassPair(boxingClass);

    return [boxingClass box:aPtr];
}

+ (id)box:(void *)aPtr
{
    return [[[self allocWithZone:NULL] initWithPtr:aPtr] autorelease];
}

+ (void)unbox:(id)aValue to:(void *)aDest usingType:(const char *)aType
{
    aType = [self _skipQualifiers:aType];

    switch(*aType) {
        case _C_ID:
        case _C_CLASS:    *(id*)aDest                  = aValue;                          break;
        case _C_SEL:      *(SEL*)aDest                 = NSSelectorFromString(aValue);    break;
        case _C_CHARPTR:  *(const char **)aDest        = [aValue UTF8String];             break;
        case _C_DBL:      *(double *)aDest             = [aValue doubleValue];            break;
        case _C_FLT:      *(float *)aDest              = [aValue floatValue];             break;
        case _C_INT:      *(int *)aDest                = [aValue intValue];               break;
        case _C_CHR:      *(char *)aDest               = [aValue charValue];              break;
        case _C_SHT:      *(short *)aDest              = [aValue shortValue];             break;
        case _C_BOOL:     *(_Bool *)aDest              = [aValue boolValue];              break;
        case _C_LNG:      *(long *)aDest               = [aValue longValue];              break;
        case _C_LNG_LNG:  *(long long *)aDest          = [aValue longLongValue];          break;
        case _C_UINT:     *(unsigned int *)aDest       = [aValue unsignedIntValue];       break;
        case _C_USHT:     *(unsigned short *)aDest     = [aValue unsignedShortValue];     break;
        case _C_ULNG:     *(unsigned long *)aDest      = [aValue unsignedLongValue];      break;
        case _C_ULNG_LNG: *(unsigned long long *)aDest = [aValue unsignedLongLongValue];  break;

        case _MR_C_LAMBDA_B: {
            if(*(aType+1) == _MR_C_LAMBDA_FUNCPTR) {
                [NSException raise:@"Unimplemented"
                            format:@"Unboxing a block to a function pointer has not been implemented yet."];
                return;
            }
            TQBoxedBlockLiteral *wrapperBlock = (TQBoxedBlockLiteral *)aValue;
            if(!(wrapperBlock->flags & TQ_BLOCK_IS_WRAPPER_BLOCK)) {
                NSLog(@"%@ is not a wrapper block", aValue);
                return;
            }
            memmove(aDest, wrapperBlock->funPtr, sizeof(void*));
        } break;

        case _C_STRUCT_B: {
            NSUInteger size;
            NSGetSizeAndAlignment(aType, &size, NULL);

            // If it's a boxed object we just make sure the sizes match and then copy the bits
            if([aValue isKindOfClass:self]) {
                TQBoxedObject *value = aValue;
                assert(value->_size == size);
                memmove(aDest, value->_ptr, size);
            }
            // If it's an array  we unbox based on indices
            else if([aValue isKindOfClass:[NSArray class]] || [aValue isKindOfClass:[NSPointerArray class]]) {
                NSArray *arr = aValue;
                NSUInteger size;
                NSUInteger ofs = 0;
                const char *fieldType = strstr(aType, "=") + 1;
                assert((uintptr_t)fieldType > 1);
                const char *next;
                for(id obj in arr) {
                    next = NSGetSizeAndAlignment(fieldType, &size, NULL);
                    [TQBoxedObject unbox:obj to:(char*)aDest + ofs usingType:fieldType];
                    if(*next == _C_STRUCT_E)
                        break;
                    fieldType = next;
                    ofs += size;
                }
            }
            // If it's a dictionary we can unbox based on it's keys
            else if([aValue isKindOfClass:[NSDictionary class]] || [aValue isKindOfClass:[NSMapTable class]]) {
                  [NSException raise:@"Unimplemented"
                           format:@"Dictionary unboxing has not been implemented yet."];

            } else {
               [NSException raise:@"Invalid value"
                           format:@"You tried to unbox %@ to a struct, but it can not.", aValue];
            }
        } break;
        case _C_UNION_B: {
            [NSException raise:@"Unimplemented"
                        format:@"Unboxing to a union has not been implemented yet."];

        }
        default:
            TQAssert(NO, @"Tried to unbox unsupported type '%c' in %s!", *aType, aType);
    }
}

- (id)initWithPtr:(void *)aPtr
{
    [NSException raise:@"Invalid Receiver" format:@"TQBoxedObject is an abstract class. Do not try to instantiate it directly."];
    // Implemented by subclasses
    return nil;
}

- (void)dealloc
{
    if(_isOnHeap)
        free(_ptr);
    [super dealloc];
}

- (void)moveValueToHeap
{
    if(_isOnHeap)
        return;

    void *stackAddr = _ptr;
    _ptr = malloc(_size);
    memmove(_ptr, stackAddr, _size);
    _isOnHeap = YES;
}

- (id)retain
{
    id ret = [super retain];
    [self moveValueToHeap];
    return ret;
}

- (id)copyWithZone:(NSZone *)aZone
{
    TQBoxedObject *ret = [[[self class] allocWithZone:aZone] initWithPtr:_ptr];
    [ret moveValueToHeap];
    return ret;
}

#pragma mark -

+ (NSString *)_getFieldName:(const char **)aType
{
    if(*(*aType) != '"')
        return NULL;
    *aType = *aType + 1;
    const char *nameEnd = strstr(*aType, "\"");
    int len = nameEnd - *aType;

    NSString *ret = [[NSString alloc] initWithBytes:*aType length:len encoding:NSUTF8StringEncoding];
    (*aType) += len+1;
    return [ret autorelease];
}

+ (BOOL)typeIsScalar:(const char *)aType
{
    return !(*aType == _C_STRUCT_B || *aType == _C_UNION_B || *aType == _C_ARY_B || *aType == _MR_C_LAMBDA_B || *aType == _C_PTR);
}

+ (const char *)_findEndOfPair:(const char *)aStr start:(char)aStartChar end:(char)aEndChar
{
    for(int i = 0, depth = 0; i < strlen(aStr); ++i) {
        if(aStr[i] == aStartChar)
            ++depth;
        else if(aStr[i] == aEndChar) {
            if(--depth == 0)
                return aStr+i;
        }
    }
    return NULL;
}

// Skips type qualifiers and alignments neither of which is used at the moment
+ (const char *)_skipQualifiers:(const char *)aType
{
    while(*aType == 'r' || *aType == 'n' || *aType == 'N' || *aType == 'o' || *aType == 'O'
          || *aType == 'R' || *aType == 'V' || (*aType >= '0' && *aType <= '9')) {
        ++aType;
    }
    return aType;
}

+ (NSString *)_classNameForType:(const char *)aType
{
    NSUInteger len;
    if(*aType == _C_STRUCT_B)
        len = [self _findEndOfPair:aType start:_C_STRUCT_B end:_C_STRUCT_E] - aType + 1;
    else if(*aType == _C_UNION_B)
        len = [self _findEndOfPair:aType start:_C_UNION_B end:_C_UNION_E] - aType + 1;
    else if(*aType == _C_ARY_B)
        len = [self _findEndOfPair:aType start:_C_ARY_B end:_C_ARY_E] - aType + 1;
    else if(*aType == _MR_C_LAMBDA_B)
        len = [self _findEndOfPair:aType start:_MR_C_LAMBDA_B end:_MR_C_LAMBDA_E] - aType + 1;
    else if(*aType == _C_PTR) {
        const char *nextType = NSGetSizeAndAlignment(aType, NULL, NULL);
        len = nextType - aType;
    } else
        len = 1;

    len += strlen(TQBoxedObject_PREFIX) + 1;
    char className[len+1];
    snprintf(className, len, "%s%s", TQBoxedObject_PREFIX, aType);

    return [NSString stringWithUTF8String:className];
}

+ (Class)_prepareScalarWrapper:(const char *)aClassName withType:(const char *)aType
{
    NSUInteger size, alignment;
    NSGetSizeAndAlignment(aType, &size, &alignment);

    IMP initImp      = nil;
    Class superClass = self;
    switch(*aType) {
        case _C_ID:
        case _C_CLASS:    initImp = (IMP)_box_C_ID_imp;       break;
        case _C_SEL:      initImp = (IMP)_box_C_SEL_imp;      break;
        case _C_VOID:     initImp = (IMP)_box_C_VOID_imp;     break;
        case _C_CHARPTR:  initImp = (IMP)_box_C_CHARPTR_imp;  break;
        case _C_DBL:      initImp = (IMP)_box_C_DBL_imp;      break;
        case _C_FLT:      initImp = (IMP)_box_C_FLT_imp;      break;
        case _C_INT:      initImp = (IMP)_box_C_INT_imp;      break;
        case _C_CHR:      initImp = (IMP)_box_C_CHR_imp;      break;
        case _C_SHT:      initImp = (IMP)_box_C_SHT_imp;      break;
        case _C_BOOL:     initImp = (IMP)_box_C_BOOL_imp;     break;
        case _C_LNG:      initImp = (IMP)_box_C_LNG_imp;      break;
        case _C_LNG_LNG:  initImp = (IMP)_box_C_LNG_LNG_imp;  break;
        case _C_UINT:     initImp = (IMP)_box_C_UINT_imp;     break;
        case _C_USHT:     initImp = (IMP)_box_C_USHT_imp;     break;
        case _C_ULNG:     initImp = (IMP)_box_C_ULNG_imp;     break;
        case _C_ULNG_LNG: initImp = (IMP)_box_C_ULNG_LNG_imp; break;

        default:
            [NSException raise:NSGenericException
                        format:@"Unsupported scalar type %c!", *aType];
            return nil;
    }

    Class kls = objc_allocateClassPair(superClass, aClassName, 0);
    class_addMethod(kls->isa, @selector(box:), initImp, "@:^v");

    return kls;
}

// Handles unions&structs
+ (Class)_prepareAggregateWrapper:(const char *)aClassName withType:(const char *)aType
{
    BOOL isStruct = *aType == _C_STRUCT_B;
    Class kls = objc_allocateClassPair(self, aClassName, 0);

    NSUInteger size, alignment;
    NSGetSizeAndAlignment(aType, &size, &alignment);

    // Store the accessors sequentially in order to allow indexed access (necessary for structs without field name information)
    NSMutableArray *fieldGetters = [NSMutableArray array];
    NSMutableArray *fieldSetters = [NSMutableArray array];

    id fieldGetter, fieldSetter;
    NSUInteger fieldSize, fieldOffset;
    const char *nextType;
    const char *fieldType = strstr(aType, "=")+1;
    assert((uintptr_t)fieldType > 1);

    // Add properties for each field
    fieldOffset = 0;
    while((nextType = NSGetSizeAndAlignment(fieldType, &fieldSize, NULL))) {
        NSString *name = [self _getFieldName:&fieldType];
        fieldGetter = [[^(TQBoxedObject *self) {
            return [TQBoxedObject box:(char*)self->_ptr+fieldOffset withType:fieldType];
        } copy] autorelease];
        fieldSetter = [[^(TQBoxedObject *self, id value) {
            [TQBoxedObject unbox:value to:(char*)self->_ptr+fieldOffset usingType:fieldType];
        } copy] autorelease];

        if(name) {
            class_addMethod(kls, NSSelectorFromString(name), BlockImp(fieldGetter), "@:");
            class_addMethod(kls, NSSelectorFromString([NSString stringWithFormat:@"set%@:", [name capitalizedString]]), BlockImp(fieldSetter), "@:@");
        }
        [fieldGetters addObject:fieldGetter];
        [fieldSetters addObject:fieldSetter];

        if((isStruct && *nextType == _C_STRUCT_E) || (!isStruct && *nextType == _C_UNION_E))
            break;
        // If it's a union, the offset is always 0
        if(isStruct)
            fieldOffset += fieldSize;
        fieldType = nextType;
    }

    IMP subscriptGetterImp = BlockImp(^(id self, NSInteger idx) {
        id (^getter)(id) = [fieldGetters objectAtIndex:idx];
        return getter(self);
    });
    const char *subscrGetterType = [[NSString stringWithFormat:@"@:%s", @encode(NSInteger)] UTF8String];
    class_addMethod(kls, @selector(objectAtIndexedSubscript:), subscriptGetterImp, subscrGetterType);
    IMP subscriptSetterImp = BlockImp(^(id self, id value, NSInteger idx) {
        id (^setter)(id, id) = [fieldSetters objectAtIndex:idx];
        return setter(self, value);
    });
    const char *subscrSetterType = [[NSString stringWithFormat:@"@:@%s", @encode(NSInteger)] UTF8String];
    class_addMethod(kls, @selector(setObject:atIndexedSubscript:), subscriptSetterImp, subscrSetterType);

    IMP initImp = BlockImp(^(TQBoxedObject *self, void *aPtr) {
        self->_ptr  = aPtr;
        self->_size = size;
        return self;
    });
    class_addMethod(kls, @selector(initWithPtr:), initImp, "@:^v");

    return kls;
}

// Handles blocks&function pointers
+ (Class)_prepareLambdaWrapper:(const char *)aClassName withType:(const char *)aType
{
    BOOL isBlock = *(++aType) == _MR_C_LAMBDA_BLOCK;

    BOOL needsWrapping = NO;
    // If the value is a funptr, the return value or any argument is not an object, then the value needs to be wrapped up
    for(int i = 0; i < strlen(aType)-1; ++i) {
        if(aType[i] != _C_ID) {
            needsWrapping = YES;
            break;
        }
    }

    Class kls = objc_allocateClassPair(self, aClassName, 0);

    IMP initImp;
    if(!needsWrapping) {
        initImp = (IMP)_box_C_ID_imp;
    } else {
        const char *argTypes;
        // Figure out the return type
        TQFFIType *retType = [TQFFIType typeWithEncoding:aType+1 nextType:&argTypes];

        // And now the argument types
        NSUInteger numArgs = isBlock;
        NSUInteger argSize, currArgSize;
        argSize = 0;
        if(*argTypes != _MR_C_LAMBDA_E) {
            const char *currArg = argTypes;
            while((currArg = NSGetSizeAndAlignment(currArg, &currArgSize, NULL))) {
                ++numArgs;
                argSize += currArgSize;
                if(*currArg == _MR_C_LAMBDA_E)
                    break;
            }
        }

        ffi_cif *cif = (ffi_cif*)malloc(sizeof(ffi_cif));
        ffi_type **args = (ffi_type**)malloc(sizeof(ffi_type*)*numArgs);
        NSMutableArray *argTypeObjects = [NSMutableArray arrayWithCapacity:numArgs];

        int argIdx = 0;
        if(isBlock) {
            args[argIdx++] = &ffi_type_pointer;
            argSize += sizeof(void*);
        }

        TQFFIType *currTypeObj;
        for(int i = isBlock; i < numArgs; ++i) {
            currTypeObj = [TQFFIType typeWithEncoding:argTypes nextType:&argTypes];
            args[argIdx++] = [currTypeObj ffiType];

            [argTypeObjects addObject:currTypeObj];
        }

        if(ffi_prep_cif(cif, FFI_DEFAULT_ABI, numArgs, retType.ffiType, args) != FFI_OK) {
            // TODO: be more graceful
            NSLog(@"unable to wrap block");
            exit(1);
        }

        initImp = BlockImp(^(TQBoxedObject *self, id *aPtr) {
            // Create and return the wrapper block
            struct TQBoxedBlockLiteral blk = {
                &_NSConcreteStackBlock,
                TQ_BLOCK_IS_WRAPPER_BLOCK, 0,
                (void*)&__wrapperBlock_invoke,
                &boxedBlockDescriptor,
                isBlock ? (id)*aPtr : (id)aPtr,
                aType,
                argSize,
                cif
            };
            return [[(id)&blk copy] autorelease];
        });

        // Hold on to these guys for the life of the class:
        objc_setAssociatedObject(kls, &_TQRetTypeAssocKey, retType, OBJC_ASSOCIATION_RETAIN);
        objc_setAssociatedObject(kls, &_TQArgTypesAssocKey, argTypeObjects, OBJC_ASSOCIATION_RETAIN);
        NSPointerFunctions *pointerFuns = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsOpaqueMemory|NSPointerFunctionsOpaquePersonality];
        pointerFuns.relinquishFunction = &_freeRelinquishFunction;

        NSPointerArray *ffiResArr = [NSPointerArray  pointerArrayWithPointerFunctions:pointerFuns];
        [ffiResArr addPointer:cif];
        [ffiResArr addPointer:args];
        objc_setAssociatedObject(kls, &_TQFFIResourcesAssocKey, argTypeObjects, OBJC_ASSOCIATION_RETAIN);
    }
    class_addMethod(kls, @selector(initWithPtr:), initImp, "@:^v");

    return kls;
}

- (id)objectAtIndexedSubscript:(NSInteger)aIdx
{
    return nil;
}
- (void)setObject:(id)aValue atIndexedSubscript:(NSInteger)aIdx
{
    // Implemented by subclasses
}

@end

// Block that takes a variable number of objects and calls the original function pointer using their unboxed values
id __wrapperBlock_invoke(struct TQBoxedBlockLiteral *__blk, ...)
{
    const char *type = __blk->type;
    void *funPtr = __blk->funPtr;
    BOOL isBlock = *(type++) == _C_ID;

    void *ffiRet = alloca(__blk->cif->rtype->size);
    const char *retType = type;

    va_list argList;
    va_start(argList, __blk);

    const char *currType, *nextType;
    currType = NSGetSizeAndAlignment(retType, NULL, NULL);
    void *ffiArgs     = alloca(__blk->argSize);
    void **ffiArgPtrs = (void**)alloca(sizeof(void*) * __blk->cif->nargs);
    if(isBlock) {
        ffiArgPtrs[0] = funPtr;
        funPtr = ((struct TQBoxedBlockLiteral *)funPtr)->invoke;
    }

    id arg;
    for(int i = isBlock, ofs = 0; i < __blk->cif->nargs; ++i) {
        arg = va_arg(argList, id);
        [TQBoxedObject unbox:arg to:(char*)ffiArgs+ofs usingType:currType];
        ffiArgPtrs[i] = (char*)ffiArgs+ofs;

        ofs += __blk->cif->arg_types[i]->size;
        currType = NSGetSizeAndAlignment(currType, NULL, NULL);
    }
    va_end(argList);
    ffi_call(__blk->cif, FFI_FN(funPtr), ffiRet, ffiArgPtrs);

    // retain/autorelease to move the pointer onto the heap
    if(*retType == _C_ID)
        return *(id*)ffiRet;
    return [[[TQBoxedObject box:ffiRet withType:retType] retain] autorelease];
}

#pragma mark - Boxed msgSend

id TQBoxedMsgSend(id self, SEL selector, ...)
{
    if(!self)
        return nil;

    Method method = class_getInstanceMethod(*(Class*)self, selector);
    if(!method) {
        [NSException raise:NSGenericException
                    format:@"Unknown selector %@ sent to object %@", NSStringFromSelector(selector), self];
        return nil;
    }

    const char *encoding = method_getTypeEncoding(method);
    unsigned int nargs = method_getNumberOfArguments(method);
    IMP imp = method_getImplementation(method);

    ffi_type *retType;
    ffi_type *argTypes[nargs];
    void *argValues;      // Stores the actual arguments to pass to ffi_call
    void *argPtrs[nargs]; // Stores a list of pointers to args to pass to ffi_call
    void *retPtr = NULL;

    // Start by loading the passed objects (we store them temporarily in argPtrs to avoid an extra alloca)
    argPtrs[0] = self;
    argPtrs[1] = selector;
    va_list valist;
    va_start(valist, selector);
    for(unsigned int i = 2; i < nargs; ++i) {
        argPtrs[i] = va_arg(valist, id);
    }
    va_end(valist);

    if(TQMethodTypeRequiresBoxing(encoding)) {
        // Allocate enough space for the return value
        NSUInteger retSize;
        const char *argEncoding = NSGetSizeAndAlignment(encoding, &retSize, NULL);
        if(retSize > 0)
            retPtr = alloca(retSize);
        retType = [[TQFFIType typeWithEncoding:[TQBoxedObject _skipQualifiers:encoding]] ffiType];

        // Figure out how much space the unboxed arguments need
        const char *argType = argEncoding;
        NSUInteger totalArgSize, argSize;
        totalArgSize = 0;
        for(unsigned int i = 0; i < nargs; ++i) {
            argType = NSGetSizeAndAlignment(argType, &argSize, NULL);
            totalArgSize += argSize;
        }
        argValues = alloca(totalArgSize);

        // Actually unbox the argument list
        argType = argEncoding;
        unsigned int ofs = 0;
        for(unsigned int i = 0; i < nargs; ++i) {
            // Only unbox non-objects that come after the selector
            if(*(argType = [TQBoxedObject _skipQualifiers:argType]) != _C_ID && i >= 2) {
                [TQBoxedObject unbox:(id)argPtrs[i] to:(char*)argValues+ofs usingType:argType];
                argTypes[i] = [[TQFFIType typeWithEncoding:argType] ffiType];
            } else {
                memcpy((char*)argValues + ofs, &argPtrs[i], sizeof(void*));
                argTypes[i] = &ffi_type_pointer;
            }
            argPtrs[i] = (char*)argValues+ofs;
            argType = NSGetSizeAndAlignment(argType, &argSize, NULL);
            ofs += argSize;
        }
    } else {
        // Everything's a simple pointer
        if(*encoding == _C_ID) {
            retType = &ffi_type_pointer;
            retPtr = alloca(sizeof(void*));
        } else
            retType = &ffi_type_void;

        argValues = alloca(sizeof(void*)*nargs);
        unsigned int ofs;
        for(unsigned int i = 0; i < nargs; ++i) {
            ofs = i*sizeof(id);
            memcpy((char*)argValues + ofs, &argPtrs[i], sizeof(id));
            argPtrs[i]  = (char*)argValues + ofs;
            argTypes[i] = &ffi_type_pointer;
        }
    }

    ffi_cif cif;
    if(ffi_prep_cif(&cif, FFI_DEFAULT_ABI, nargs, retType, argTypes) != FFI_OK) {
        // TODO: be more graceful
        NSLog(@"unable to wrap method call");
        exit(1);
    }
    ffi_call(&cif, FFI_FN(imp), retPtr, argPtrs);

    if(*encoding == _C_ID)
        return *(id*)retPtr;
    else if(*encoding == _C_VOID)
        return nil;
    return [[[TQBoxedObject box:retPtr withType:encoding] retain] autorelease];
}


#pragma mark - Scalar boxing IMPs
id _box_C_ID_imp(TQBoxedObject *self, SEL _cmd, id *aPtr)                       { return *aPtr; }
id _box_C_SEL_imp(TQBoxedObject *self, SEL _cmd, SEL *aPtr)                     { return NSStringFromSelector(*aPtr); }
id _box_C_VOID_imp(TQBoxedObject *self, SEL _cmd, id *aPtr)                     { return nil; }
id _box_C_CHARPTR_imp(TQBoxedObject *self, SEL _cmd, const char *aPtr)          { return @(*aPtr); }
id _box_C_DBL_imp(TQBoxedObject *self, SEL _cmd, double *aPtr)                  { return @(*aPtr); }
id _box_C_FLT_imp(TQBoxedObject *self, SEL _cmd, float *aPtr)                   { return @(*aPtr); }
id _box_C_INT_imp(TQBoxedObject *self, SEL _cmd, int *aPtr)                     { return @(*aPtr); }
id _box_C_SHT_imp(TQBoxedObject *self, SEL _cmd, short *aPtr)                   { return @(*aPtr); }
id _box_C_CHR_imp(TQBoxedObject *self, SEL _cmd, char *aPtr)                    { return @(*aPtr); }
id _box_C_BOOL_imp(TQBoxedObject *self, SEL _cmd, _Bool *aPtr)                  { return *aPtr ? TQValid : nil; }
id _box_C_LNG_imp(TQBoxedObject *self, SEL _cmd, long *aPtr)                    { return @(*aPtr); }
id _box_C_LNG_LNG_imp(TQBoxedObject *self, SEL _cmd, long long *aPtr)           { return @(*aPtr); }
id _box_C_UINT_imp(TQBoxedObject *self, SEL _cmd, unsigned int *aPtr)           { return @(*aPtr); }
id _box_C_USHT_imp(TQBoxedObject *self, SEL _cmd, unsigned short *aPtr)         { return @(*aPtr); }
id _box_C_ULNG_imp(TQBoxedObject *self, SEL _cmd, unsigned long *aPtr)          { return @(*aPtr); }
id _box_C_ULNG_LNG_imp(TQBoxedObject *self, SEL _cmd, unsigned long long *aPtr) { return @(*aPtr); }

#pragma mark -

void _freeRelinquishFunction(const void *item, NSUInteger (*size)(const void *item))
{
    free((void*)item);
}
