#import "TQNodeBlock.h"
#import "TQNodeArgumentDef.h"
#import "TQProgram.h"
#import "TQNodeVariable.h"
// Block invoke functions are numbered from 0
#define TQ_BLOCK_FUN_PREFIX @"__tq_block_invoke_"

// The struct index where captured variables begin
#define TQ_CAPTURE_IDX 5

using namespace llvm;

@implementation TQNodeBlock
@synthesize arguments=_arguments, statements=_statements, locals=_locals, name=_name,
    basicBlock=_basicBlock, function=_function, builder=_builder, autoreleasePool=_autoreleasePool;

+ (TQNodeBlock *)node { return (TQNodeBlock *)[super node]; }

- (id)init
{
    if(!(self = [super init]))
        return nil;

    _arguments = [[NSMutableArray alloc] init];
    _statements = [[NSMutableArray alloc] init];
    _locals = [[NSMutableDictionary alloc] init];
    _function = NULL;
    _basicBlock = NULL;

    // Block invocations are always passed the block itself as the first argument
    [self addArgument:@"__blk" error:nil];

    return self;
}

- (void)dealloc
{
    [_locals release];
    [_arguments release];
    [_statements release];
    delete _basicBlock;
    delete _function;
    delete _builder;
    [super dealloc];
}

- (NSString *)description
{
    NSMutableString *out = [NSMutableString stringWithString:@"<blk@ {"];
    if(_arguments.count > 0) {
        for(NSString *arg in _arguments) {
            [out appendFormat:@"%@, ", arg];
        }
        [out appendString:@"|"];
    }
    if(_statements.count > 0) {
        [out appendString:@"\n"];
        for(TQNode *stmt in _statements) {
            [out appendFormat:@"\t%@\n", stmt];
        }
    }
    [out appendString:@"}>"];
    return out;
}

- (NSString *)signature
{
    // Return type
    NSMutableString *sig = [NSMutableString stringWithString:@"@"];
    // Argument types
    for(int i = 0; i < _arguments.count; ++i)
        [sig appendString:@"@"];
    return sig;
}

- (BOOL)addArgument:(NSString *)aArgument error:(NSError **)aoError
{
    TQAssertSoft(![_arguments containsObject:aArgument],
                 kTQSyntaxErrorDomain, kTQUnexpectedIdentifier, NO,
                 @"Duplicate arguments for '%@'", aArgument);

    [_arguments addObject:aArgument];

    return YES;
}

- (void)setStatements:(NSArray *)aStatements
{
    NSArray *old = _statements;
    _statements = [aStatements mutableCopy];
    [old release];
}


- (llvm::Type *)_blockDescriptorTypeInProgram:(TQProgram *)aProgram
{
    static Type *descriptorType = NULL;
    if(descriptorType)
        return descriptorType;

    Type *i8PtrTy = aProgram.llInt8PtrTy;
    Type *longTy  = aProgram.llInt64Ty; // Should be unsigned

    descriptorType = StructType::create("struct.__block_descriptor",
                                        longTy,  // reserved
                                        longTy,  // size ( = sizeof(literal))
                                        i8PtrTy, // copy_helper(void *dst, void *src)
                                        i8PtrTy, // dispose_helper(void *blk)
                                        NULL);
    descriptorType = PointerType::getUnqual(descriptorType);
    return descriptorType;
}

- (llvm::Type *)_genericBlockLiteralTypeInProgram:(TQProgram *)aProgram
{
    static Type *literalType = NULL;
    if(literalType)
        return literalType;

    Type *i8PtrTy = aProgram.llInt8PtrTy;
    Type *intTy   = aProgram.llIntTy;

    literalType = StructType::create("struct.__block_literal_generic",
                                     aProgram.llInt8PtrTy, // isa
                                     intTy,                // flags
                                     intTy,                // reserved
                                     i8PtrTy,              // invoke(void *blk, ...)
                                     [self _blockDescriptorTypeInProgram:aProgram],
                                     NULL);
    return literalType;
}

- (llvm::Type *)_blockLiteralTypeInProgram:(TQProgram *)aProgram
{
    if(_literalType)
        return _literalType;

    Type *i8PtrTy = aProgram.llInt8PtrTy;
    Type *intTy   = aProgram.llIntTy;

    std::vector<Type*> fields;
    fields.push_back(i8PtrTy); // isa
    fields.push_back(intTy);   // flags
    fields.push_back(intTy);   // reserved
    fields.push_back(i8PtrTy); // invoke(void *blk, ...)
    fields.push_back([self _blockDescriptorTypeInProgram:aProgram]);

    // Fields for captured vars
    Type *captureType;
    for(TQNodeVariable *var in [_capturedVariables allValues]) {
        fields.push_back(i8PtrTy);
    }

    _literalType = StructType::get(aProgram.llModule->getContext(), fields, true);
    return _literalType;
}

- (llvm::Type *)_byRefTypeInProgram:(TQProgram *)aProgram
{
    static Type *byRefType = NULL;
    if(byRefType)
        return byRefType;

    Type *i8PtrTy = aProgram.llInt8PtrTy;
    Type *intTy  = aProgram.llIntTy;

    byRefType = StructType::create("struct.__block_descriptor",
                                   i8PtrTy, i8PtrTy, intTy, intTy, i8PtrTy, NULL);
    //byRefType = PointerType::getUnqual(byRefType);
    return byRefType;
}


#pragma mark - Code generation

// Descriptor is a constant struct describing all instances of this block
- (llvm::Constant *)_generateBlockDescriptorInProgram:(TQProgram *)aProgram
{
    if(_blockDescriptor)
        return _blockDescriptor;

    llvm::Module *mod = aProgram.llModule;
    SmallVector<llvm::Constant*, 6> elements;

    // reserved
    elements.push_back(llvm::ConstantInt::get( aProgram.llInt64Ty, 0));  // TODO: Use 32bit on x86

    // Size
    elements.push_back(ConstantExpr::getSizeOf([self _blockLiteralTypeInProgram:aProgram]));

    elements.push_back([self _generateCopyHelperInProgram:aProgram]);
    elements.push_back([self _generateDisposeHelperInProgram:aProgram]);

    // Signature
    elements.push_back(ConstantExpr::getBitCast((GlobalVariable*)_builder->CreateGlobalString([[self signature] UTF8String]), aProgram.llInt8PtrTy));

    // GC Layout (unused in objc 2)
    //elements.push_back(llvm::Constant::getNullValue(aProgram.llInt8PtrTy));

    llvm::Constant *init = llvm::ConstantStruct::getAnon(elements);

    llvm::GlobalVariable *global = new llvm::GlobalVariable(*mod, init->getType(), true,
                                    llvm::GlobalValue::InternalLinkage,
                                    init, "__tq_block_descriptor_tmp");

    _blockDescriptor = llvm::ConstantExpr::getBitCast(global, [self _blockDescriptorTypeInProgram:aProgram]);

    return _blockDescriptor;
}

// The block literal is a stack allocated struct representing a single instance of this block
- (llvm::Value *)_generateBlockLiteralInProgram:(TQProgram *)aProgram parentBlock:(TQNodeBlock *)aParentBlock
{
    Module *mod = aProgram.llModule;
    IRBuilder<> *pBuilder = aParentBlock.builder;

    Type *i8PtrTy = aProgram.llInt8PtrTy;
    Type *i8PtrPtrTy = aProgram.llInt8PtrPtrTy;
    Type *intTy   = aProgram.llIntTy;

    // Build the block struct
    int BlockHeaderSize = 5;
    //llvm::Constant *fields[BlockHeaderSize];
    std::vector<Constant *> fields;

    // isa
    Value *isaPtr;
    if(mod->getNamedValue("_NSConcreteStackBlock"))
        isaPtr = llvm::ConstantExpr::getBitCast(mod->getNamedValue("_NSConcreteStackBlock"), i8PtrPtrTy);
    else
        isaPtr = new llvm::GlobalVariable(*mod, i8PtrTy, false,
                             llvm::GlobalValue::ExternalLinkage,
                             0, "_NSConcreteStackBlock", 0,
                             false, 0);
    isaPtr =  pBuilder->CreateBitCast(isaPtr, i8PtrTy);

    // __flags
    int flags = TQ_BLOCK_HAS_COPY_DISPOSE | TQ_BLOCK_HAS_SIGNATURE;
    //if (blockInfo.UsesStret) flags |= TQ_BLOCK_USE_STRET;
    Value *invoke = pBuilder->CreateBitCast(_function, i8PtrTy, "invokePtr");
    Constant *descriptor = [self _generateBlockDescriptorInProgram:aProgram];

    IRBuilder<> entryBuilder(&aParentBlock.function->getEntryBlock(), aParentBlock.function->getEntryBlock().begin());
    Type *literalTy = [self _blockLiteralTypeInProgram:aProgram];
    AllocaInst *alloca = entryBuilder.CreateAlloca(literalTy, 0, "block");
    alloca->setAlignment(8);

    pBuilder->CreateStore(isaPtr,                         pBuilder->CreateStructGEP(alloca, 0 , "block.isa"));
    pBuilder->CreateStore(ConstantInt::get(intTy, flags), pBuilder->CreateStructGEP(alloca, 1,  "block.flags"));
    pBuilder->CreateStore(ConstantInt::get(intTy, 0),     pBuilder->CreateStructGEP(alloca, 2,  "block.reserved"));
    pBuilder->CreateStore(invoke,                         pBuilder->CreateStructGEP(alloca, 3 , "block.invoke"));
    pBuilder->CreateStore(descriptor,                     pBuilder->CreateStructGEP(alloca, 4 , "block.descriptor"));

    // Now that we've initialized the basic block info, we need to capture the variables in the parent block scope
    if(_capturedVariables) {
        int i = TQ_CAPTURE_IDX;
        for(NSString *name in _capturedVariables) {
            TQNodeVariable *varToCapture = [_capturedVariables objectForKey:name];
            [varToCapture createStorageInProgram:aProgram block:aParentBlock error:nil];
            NSString *fieldName = [NSString stringWithFormat:@"block.%@", name];
            pBuilder->CreateStore(pBuilder->CreateBitCast(varToCapture.alloca, i8PtrTy), pBuilder->CreateStructGEP(alloca, i++, [fieldName UTF8String]));
        }
    }

    return pBuilder->CreateBitCast(alloca, i8PtrTy);
}

// Copies the captured variables when this block is copied to the heap
- (llvm::Function *)_generateCopyHelperInProgram:(TQProgram *)aProgram
{
    // void (*copy_helper)(void *dst, void *src)
    Type *int8PtrTy = aProgram.llInt8PtrTy;
    Type *intTy = aProgram.llIntTy;
    std::vector<Type *> paramTypes;
    paramTypes.push_back(int8PtrTy);
    paramTypes.push_back(int8PtrTy);

    FunctionType* funType = FunctionType::get(aProgram.llVoidTy, paramTypes, false);

    llvm::Module *mod = aProgram.llModule;

    const char *funName = [[NSString stringWithFormat:@"__tq_block_copy"] UTF8String];
    Function *function;
    function = Function::Create(funType, GlobalValue::ExternalLinkage, funName, mod);
    function->setCallingConv(CallingConv::C);

    BasicBlock *basicBlock = BasicBlock::Create(mod->getContext(), "entry", function, 0);
    IRBuilder<> *builder = new IRBuilder<>(basicBlock);

    Type *blockPtrTy = PointerType::getUnqual([self _blockLiteralTypeInProgram:aProgram]);

    // Load the passed arguments
    AllocaInst *dstAlloca = builder->CreateAlloca(int8PtrTy, 0, "dstBlk.alloca");
    AllocaInst *srcAlloca = builder->CreateAlloca(int8PtrTy, 0, "srcBlk.alloca");

    Function::arg_iterator args = function->arg_begin();
    builder->CreateStore(args, dstAlloca);
    builder->CreateStore(++args, srcAlloca);

    Value *dstBlock = builder->CreateBitCast(builder->CreateLoad(dstAlloca), blockPtrTy, "dstBlk");
    Value *srcBlock = builder->CreateBitCast(builder->CreateLoad(srcAlloca), blockPtrTy, "srcBlk");
    Value *flags = ConstantInt::get(intTy, TQ_BLOCK_FIELD_IS_BYREF);

    int i = TQ_CAPTURE_IDX;
    Value *varToCopy, *destAddr;
    for(TQNodeVariable *var in [_capturedVariables allValues]) {
        NSString *dstName = [NSString stringWithFormat:@"dstBlk.%@Addr", var.name];
        NSString *srcName = [NSString stringWithFormat:@"srcBlk.%@", var.name];

        destAddr  = builder->CreateBitCast(builder->CreateStructGEP(dstBlock, i), int8PtrTy, [dstName UTF8String]);
        varToCopy = builder->CreateLoad(builder->CreateStructGEP(srcBlock, i++), [srcName UTF8String]);

        builder->CreateCall3(aProgram._Block_object_assign, destAddr, varToCopy, flags);
    }

    builder->CreateRetVoid();
    return function;
}

// Releases the captured variables when this block's retain count reaches 0
- (llvm::Function *)_generateDisposeHelperInProgram:(TQProgram *)aProgram
{
    // void dispose_helper(void *src)
    Type *int8PtrTy = aProgram.llInt8PtrTy;
    std::vector<Type *> paramTypes;
    Type *intTy = aProgram.llIntTy;
    paramTypes.push_back(int8PtrTy);

    FunctionType *funType = FunctionType::get(aProgram.llVoidTy, paramTypes, false);

    llvm::Module *mod = aProgram.llModule;

    const char *funName = [[NSString stringWithFormat:@"__tq_block_dispose"] UTF8String];
    Function *function;
    function = Function::Create(funType, GlobalValue::ExternalLinkage, funName, mod);
    function->setCallingConv(CallingConv::C);

    BasicBlock *basicBlock = BasicBlock::Create(mod->getContext(), "entry", function, 0);
    IRBuilder<> *builder = new IRBuilder<>(basicBlock);
    // Load the block
    AllocaInst *blkAlloca = builder->CreateAlloca(int8PtrTy, 0, "block.alloca");
    builder->CreateStore(function->arg_begin(), blkAlloca);

    [aProgram insertLogUsingBuilder:builder withStr:@"Disposing of block"];

    Value *block = builder->CreateBitCast(builder->CreateLoad(blkAlloca), PointerType::getUnqual([self _blockLiteralTypeInProgram:aProgram]), "block");
    Value *flags = ConstantInt::get(intTy, TQ_BLOCK_FIELD_IS_BYREF);//|TQ_BLOCK_FIELD_IS_OBJECT);

    int i = TQ_CAPTURE_IDX;
    Value *varToDisposeOf;
    for(TQNodeVariable *var in [_capturedVariables allValues]) {
        NSString *name = [NSString stringWithFormat:@"block.%@", var.name];
        varToDisposeOf =  builder->CreateLoad(builder->CreateStructGEP(block, i++), [name UTF8String]);
        builder->CreateCall2(aProgram._Block_object_dispose, varToDisposeOf, flags);
    }

    builder->CreateRetVoid();
    return function;
}

// Invokes the body of this block
- (llvm::Function *)_generateInvokeInProgram:(TQProgram *)aProgram error:(NSError **)aoErr
{
    if(_function)
        return _function;

    llvm::PointerType *int8PtrTy = aProgram.llInt8PtrTy;

    // Build the invoke function
    std::vector<Type *> paramTypes(_arguments.count, int8PtrTy);
    FunctionType* funType = FunctionType::get(int8PtrTy, paramTypes, false); // TODO: Support variadics

    llvm::Module *mod = aProgram.llModule;

    const char *funName = [[NSString stringWithFormat:@"__tq_block_invoke"] UTF8String];

    _function = Function::Create(funType, GlobalValue::ExternalLinkage, funName, mod);

    _basicBlock = BasicBlock::Create(mod->getContext(), "entry", _function, 0);
    _builder = new IRBuilder<>(_basicBlock);

    _autoreleasePool = _builder->CreateCall(aProgram.objc_autoreleasePoolPush);

    // Load the arguments
    llvm::Function::arg_iterator argumentIterator = _function->arg_begin();
    Value *thisBlock = NULL;
    if([_arguments count] > 0) {
        thisBlock = _builder->CreateBitCast(argumentIterator, PointerType::getUnqual([self _blockLiteralTypeInProgram:aProgram]));
        argumentIterator++;
    }

    for (unsigned i = 1; i < _arguments.count; ++i, ++argumentIterator)
    {
        IRBuilder<> tempBuilder(&_function->getEntryBlock(), _function->getEntryBlock().begin());
        NSString *argument = [_arguments objectAtIndex:i];
        TQNodeVariable *local = [TQNodeVariable nodeWithName:argument];
        [local store:argumentIterator inProgram:aProgram block:self error:aoErr];
        [_locals setObject:local forKey:argument];
    }

    // Load captured variables
    if(thisBlock) {
        int i = TQ_CAPTURE_IDX;
        TQNodeVariable *varToLoad;
        for(NSString *name in [_capturedVariables allKeys]) {
            varToLoad = [TQNodeVariable nodeWithName:name];
            Value *valueToLoad = _builder->CreateLoad(_builder->CreateStructGEP(thisBlock, i++), [name UTF8String]);
            valueToLoad = _builder->CreateBitCast(valueToLoad, PointerType::getUnqual([varToLoad captureStructTypeInProgram:aProgram]));
            varToLoad.alloca = (AllocaInst *)valueToLoad;

            [_locals setObject:varToLoad forKey:name];
        }
    }

    Value *val;
    for(TQNode *stmt in _statements) {
        [stmt generateCodeInProgram:aProgram block:self error:aoErr];
        if(*aoErr) {
            NSLog(@"Error: %@", *aoErr);
            return NULL;
        }
        if([stmt isKindOfClass:[TQNodeReturn class]])
            break;
    }

    if(!_basicBlock->getTerminator()) {
        _builder->CreateCall(aProgram.objc_autoreleasePoolPop, _autoreleasePool);
        ReturnInst::Create(mod->getContext(), ConstantPointerNull::get(int8PtrTy), _basicBlock);
    }
    return _function;
}

// Generates a block on the stack
- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
    TQAssert(!_basicBlock && !_function, @"Tried to regenerate code for block %@", _name);

    // Generate a list of variables to capture
    if(aBlock) {
        _capturedVariables = [[NSMutableDictionary alloc] init];
        for(NSString *name in [aBlock.locals allKeys]) {
            if([_locals objectForKey:name])
                continue; // Arguments to this block override locals in the parent (Not that  you should write code like that)
            TQNodeVariable *parentVar = [aBlock.locals objectForKey:name];
            if(![self referencesNode:parentVar])
                continue;
            [_capturedVariables setObject:[aBlock.locals objectForKey:name] forKey:name];
        }
    }

    if(![self _generateInvokeInProgram:aProgram error:aoErr])
        return NULL;

    Value *literal = [self _generateBlockLiteralInProgram:aProgram parentBlock:aBlock];

    return literal;
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    TQNode *ref = nil;

    if((ref = [_statements tq_referencesNode:aNode]))
        return ref;
    NSLog(@"%@ did NOT reference %@",self, aNode);
    return nil;
}


@end


#pragma mark - Root block

@implementation TQNodeRootBlock

- (id)init
{
    if(!(self = [super init]))
        return nil;

    // No arguments for the root block ([super init] adds the block itself as an arg)
    [self.arguments removeAllObjects];

    return self;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
    // The root block is just a function that executes the body of the program
    // so we only need to create&return it's invocation function
    return [self _generateInvokeInProgram:aProgram error:aoErr];
}

@end
