#import "TQBlockClosure.h"
#import "TQFFIType.h"
#import "TQBoxedObject.h"

static ffi_closure *_AllocateClosure(void **codePtr);
static void _DeallocateClosure(void *closure);
static ffi_status _PrepareClosure(ffi_closure *closure, ffi_cif *cif, void (*fun)(ffi_cif*,void*,void**,void*), void *user_data, void *codeloc);

static void _closureFunction(ffi_cif *closureCif, void *ret, void *args[], TQBlockClosure *closureObj);
static void _blockClosureFunction(ffi_cif *closureCif, void *ret, void *args[], TQBlockClosure *closureObj);

static void TQClosureBlock_copy(struct TQClosureBlockLiteral *dst, struct TQClosureBlockLiteral *src);
static void TQClosureBlock_dispose(struct TQClosureBlockLiteral *src);

struct TQClosureBlockDescriptor _BlockDescriptor = { 0, sizeof(struct TQBlockLiteral),
                                                     &TQClosureBlock_copy, &TQClosureBlock_dispose };

@implementation TQBlockClosure
@synthesize pointer=_pointer;

- (id)initWithBlock:(id)aBlock type:(const char *)aType
{
    assert(*aType == _TQ_C_LAMBDA_B);
    BOOL isBlock = *(aType+1) == _TQ_C_LAMBDA_BLOCK;
    aType += 2;
    _type = aType;

    _block = aBlock;

    ffi_closure *closure = _AllocateClosure(&_functionPointer);
    if(closure) {
        const char *typeIterator = _type;
        _ffiTypeObjects = [NSMutableArray new];
        TQFFIType *retTypeObj = [TQFFIType typeWithEncoding:typeIterator nextType:&typeIterator];
        [_ffiTypeObjects addObject:retTypeObj];
        while(typeIterator && *typeIterator != _TQ_C_LAMBDA_E) {
            [_ffiTypeObjects addObject:[TQFFIType typeWithEncoding:typeIterator nextType:&typeIterator]];
        }

        _cif = (ffi_cif *)malloc(sizeof(ffi_cif));
        unsigned int nargs = [_ffiTypeObjects count] - 1;
        if(isBlock)
            ++nargs;
        _argTypes = (ffi_type**)malloc(sizeof(void*)*nargs);
        int i = 0;
        if(isBlock)
            _argTypes[i++] = &ffi_type_pointer;
        for(; i < nargs; ++i) {
            _argTypes[i] = [[_ffiTypeObjects objectAtIndex:isBlock ? i : i+1] ffiType];
        }

        if(ffi_prep_cif(_cif, FFI_DEFAULT_ABI, nargs, [retTypeObj ffiType], _argTypes) == FFI_OK) {
            if(_PrepareClosure(closure, _cif, (void (*)(ffi_cif*,void*,void**,void*))_blockClosureFunction, self, _functionPointer) == FFI_OK)
                objc_setAssociatedObject(_block, (void*)_cif, self, OBJC_ASSOCIATION_RETAIN);
        }
    }

    if(isBlock) {
        _boxedBlock.isa        = &_NSConcreteStackBlock;
        _boxedBlock.flags      = TQ_BLOCK_HAS_COPY_DISPOSE;
        _boxedBlock.invoke     = _functionPointer;
        _boxedBlock.descriptor = &_BlockDescriptor;
        _boxedBlock.closure    = self;
    }
    _pointer = isBlock ? &_boxedBlock : _functionPointer;
    return self;
}

- (void)dealloc
{
    _DeallocateClosure(_closure);
    free(_cif);
    free(_argTypes);
    [_ffiTypeObjects release];

    [super dealloc];
}
@end

void _closureFunction(ffi_cif *closureCif, void *ret, void *args[], TQBlockClosure *closureObj)
{
    // Construct an ffi call to the block that forwards the arguments passed to the closure
    struct TQBlockLiteral *block = (struct TQBlockLiteral *)closureObj->_block;
    unsigned int nargs = closureCif->nargs + 1;
    ffi_type *retType  = &ffi_type_pointer;
    ffi_type *argTypes[nargs];
    void     *argPtrs[nargs];

    const char *returnType = closureObj->_type;
    const char *typeEncoding = TQGetSizeAndAlignment(returnType, NULL, NULL);

    argTypes[0] = &ffi_type_pointer;
    argPtrs[0]  = (id*)&block;
    id argValues[closureCif->nargs];
    for(int i = 1; i <= closureCif->nargs; ++i) {
        argTypes[i] = &ffi_type_pointer;
        argValues[i-1] = [TQBoxedObject box:args[i-1] withType:typeEncoding];
        argPtrs[i] = &argValues[i-1];
        typeEncoding = TQGetSizeAndAlignment(typeEncoding, NULL, NULL);
    }

    // Call the block
    ffi_cif callCif;
    if(ffi_prep_cif(&callCif, FFI_DEFAULT_ABI, nargs, retType, argTypes) != FFI_OK) {
        // TODO: be more graceful
        TQLog(@"unable to wrap block call");
        exit(1);
    }
    id retPtr;
    ffi_call(&callCif, FFI_FN(block->invoke), &retPtr, argPtrs);

    if(*returnType == _C_ID)
        *(id*)ret = retPtr;
    else if(*returnType != _C_VOID)
        [TQBoxedObject unbox:retPtr to:ret usingType:returnType];
}

void _blockClosureFunction(ffi_cif *closureCif, void *ret, void *args[], TQBlockClosure *closureObj)
{
    // Construct an ffi call to the block that forwards the arguments passed to the closure
    struct TQBlockLiteral *block = (struct TQBlockLiteral *)closureObj->_block;
    unsigned int nargs = closureCif->nargs;
    ffi_type *retType  = &ffi_type_pointer;
    ffi_type *argTypes[nargs];
    void     *argPtrs[nargs];

    const char *returnType = closureObj->_type;
    const char *typeEncoding = TQGetSizeAndAlignment(returnType, NULL, NULL);

    argTypes[0] = &ffi_type_pointer;
    argPtrs[0]  = (id*)&block;
    id argValues[closureCif->nargs];
    for(int i = 2; i <= closureCif->nargs; ++i) {
        argTypes[i-1] = &ffi_type_pointer;
        argValues[i-1] = [TQBoxedObject box:args[i-1] withType:typeEncoding];
        argPtrs[i-1] = &argValues[i-1];
        typeEncoding = TQGetSizeAndAlignment(typeEncoding, NULL, NULL);
    }

    // Call the block
    ffi_cif callCif;
    if(ffi_prep_cif(&callCif, FFI_DEFAULT_ABI, nargs, retType, argTypes) != FFI_OK) {
        // TODO: be more graceful
        TQLog(@"unable to wrap block call");
        exit(1);
    }
    id retPtr;
    ffi_call(&callCif, FFI_FN(block->invoke), &retPtr, argPtrs);

    if(*returnType == _C_ID)
        *(id*)ret = retPtr;
    else if(*returnType != _C_VOID)
        [TQBoxedObject unbox:retPtr to:ret usingType:returnType];
}

void TQClosureBlock_copy(struct TQClosureBlockLiteral *dst, struct TQClosureBlockLiteral *src)
{
    _Block_object_assign(&dst->closure, src->closure, TQ_BLOCK_FIELD_IS_OBJECT);
}
void TQClosureBlock_dispose(struct TQClosureBlockLiteral *src)
{
    _Block_object_dispose(src->closure, TQ_BLOCK_FIELD_IS_OBJECT);
}


#pragma mark - LibFFI Utilities
static ffi_closure *_AllocateClosure(void **codePtr)
{
#if USE_LIBFFI_CLOSURE_ALLOC
    return ffi_closure_alloc(sizeof(ffi_closure), codePtr);
#else
    ffi_closure *closure = (ffi_closure *)mmap(NULL, sizeof(ffi_closure), PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);
    if(closure == (void *)-1) {
        perror("mmap");
        return NULL;
    }
    *codePtr = closure;
    return closure;
#endif
}

static void _DeallocateClosure(void *closure)
{
#if USE_LIBFFI_CLOSURE_ALLOC
    ffi_closure_free(closure);
#else
    munmap(closure, sizeof(ffi_closure));
#endif
}

static ffi_status _PrepareClosure(ffi_closure *closure, ffi_cif *cif, void (*fun)(ffi_cif*,void*,void**,void*), void *user_data, void *codeloc)
{
#if USE_LIBFFI_CLOSURE_ALLOC
    return ffi_prep_closure_loc(closure, cif, fun, user_data, codeloc);
#else
    ffi_status status = ffi_prep_closure(closure, cif, fun, user_data);
    if(status != FFI_OK)
        return status;
    if(mprotect(closure, sizeof(closure), PROT_READ | PROT_EXEC) == -1)
        return (ffi_status)1;
    return FFI_OK;
#endif
}
