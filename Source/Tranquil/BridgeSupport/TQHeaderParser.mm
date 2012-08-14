#import "TQHeaderParser.h"
#import "../Tranquil.h"
#import "../TQDebug.h"
#import "../Runtime/NSString+TQAdditions.h"
#import <objc/runtime.h>

using namespace llvm;

@interface TQHeaderParser ()
@property(readonly) NSMutableDictionary *functions, *classes, *literalConstants, *constants, *protocols, *typedefs;
@property(readwrite, retain) TQBridgedClassInfo *currentClass;

- (const char *)encodingForBlockPtrCursor:(CXCursor)cursor;
- (const char *)encodingForCursor:(CXCursor)cursor;
@end

static void _indexerCallback(CXClientData client_data, const CXIdxDeclInfo *declaration)
{
    @autoreleasepool {
        if(!declaration->entityInfo->name)
            return;

        TQHeaderParser *parser  = (id)client_data;
        NSString *name          = [NSString stringWithUTF8String:declaration->entityInfo->name];
        CXCursor cursor         = declaration->cursor;

        switch(declaration->entityInfo->kind) {
            case CXIdxEntity_Function: {
                // TODO: Support bridging variadic functions, support or ignore inlined functions
                const char *encoding = clang_getCString(clang_getDeclObjCTypeEncoding(cursor));
                TQBridgedFunction *fun = [TQBridgedFunction functionWithName:name
                                                                    encoding:encoding];
                [parser.functions setObject:fun
                                     forKey:[name stringByCapitalizingFirstLetter]];

            } break;
            case CXIdxEntity_ObjCClass: {
                const CXIdxObjCContainerDeclInfo *objcInfo = clang_index_getObjCContainerDeclInfo(declaration);
                // ignore forwards
                if(objcInfo->kind != CXIdxObjCContainer_Interface)
                    break;

                const CXIdxObjCInterfaceDeclInfo *interfaceInfo = clang_index_getObjCInterfaceDeclInfo(declaration);
                const CXIdxBaseClassInfo *super = interfaceInfo->superInfo;
                //NSLog(@"@interface %@ : %s\n",name, super ? super->base->name : "<none>");
                const CXIdxObjCProtocolRefListInfo *protocols = interfaceInfo->protocols;
                const CXIdxEntityInfo *protocol;
                TQBridgedClassInfo *protocolInfo;
                TQBridgedClassInfo *info = [TQBridgedClassInfo new];
                for(int i = 0; i < protocols->numProtocols; ++i) {
                    protocol = protocols->protocols[i]->protocol;
                    protocolInfo = [parser.protocols objectForKey:[NSString stringWithUTF8String:protocol->name]];
                    if(!protocolInfo)
                        continue;
                    [info.instanceMethods addEntriesFromDictionary:protocolInfo.instanceMethods];
                    [info.classMethods    addEntriesFromDictionary:protocolInfo.classMethods];
                }

                info.name = name;
                [parser.classes setObject:info forKey:name];
                parser.currentClass = info;
                [info release];
            } break;
            case CXIdxEntity_ObjCCategory: {
                const CXIdxObjCCategoryDeclInfo *categoryInfo = clang_index_getObjCCategoryDeclInfo(declaration);
                assert(categoryInfo && categoryInfo->objcClass->name);
                NSString *className = [NSString stringWithUTF8String:categoryInfo->objcClass->name];
                //NSLog(@"@interface %@ (%@)", className, name);
                parser.currentClass = [parser.classes objectForKey:className];
            } break;
            case CXIdxEntity_Typedef: {
                if(![name hasPrefix:@"NS"])
                    break;
                CXType type = clang_getTypedefDeclUnderlyingType(cursor);
                if(type.kind != CXType_BlockPointer)
                    break;
                printf("foo: %s\n", clang_getCString(clang_getTypeKindSpelling(type.kind)));
                printf("typedef: %d %d %s %s\n", type.kind, cursor.kind, [name UTF8String], clang_getCString(clang_getDeclObjCTypeEncoding(cursor)));
                clang_visitChildrenWithBlock(cursor, ^(CXCursor child, CXCursor parent) {
                    //if(child.kind == CXCursor_ParmDecl)
                        //return CXChildVisit_Recurse;
                    const char *childEnc = [parser encodingForCursor:child];
                    printf("    %d %s -- %s\n", child.kind, childEnc, clang_getCString(clang_getCursorSpelling(child)));
                    if(child.kind == 43) {
                        CXType typeDef = clang_getCursorType(child);
                        if(typeDef.kind == CXType_Typedef) { // Verify that it's in fact a typedef
                            printf("      typedef!\n");
                            CXType type = clang_getTypedefDeclUnderlyingType(child);
                            printf("      underlying type: %p\n", type.kind);
                        }
                        //const char *declEnc = tq_clang_getDeclObjCTypeEncoding(decl);
                        //printf("       %d %s -- %s\n", decl.kind, declEnc, clang_getCString(clang_getCursorSpelling(decl)));
                    }
                    return CXChildVisit_Continue;
                });

            } break;
            case CXIdxEntity_ObjCClassMethod:
            case CXIdxEntity_ObjCInstanceMethod: {
                if(declaration->isImplicit || !parser.currentClass)
                    break;
                BOOL isClassMethod = declaration->entityInfo->kind == CXIdxEntity_ObjCClassMethod;
                NSString *selector = name;
                NSString *encoding = [NSString stringWithUTF8String:[parser encodingForCursor:cursor]];
                NSLog(@"[%@ %@] %@ %d", parser.currentClass.name, selector, encoding, declaration->entityInfo->kind);
                if(isClassMethod)
                    [parser.currentClass.classMethods    setObject:encoding forKey:selector];
                else
                    [parser.currentClass.instanceMethods setObject:encoding forKey:selector];
            } break;
            case CXIdxEntity_ObjCProtocol: {
                //NSLog(@"@protocol %@\n", name);
                TQBridgedClassInfo *info = [TQBridgedClassInfo new];
                info.name = name;
                [parser.protocols setObject:info forKey:name];
                parser.currentClass = info;
                [info release];
            } break;
            case CXIdxEntity_ObjCProperty:
                // Properties are not specially handled right now
            break;
            default:
                //NSLog(@"Unhandled Objective-C entity: %@", name);
                break;
        }
    }
}

static IndexerCallbacks indexerCallbacks = {
    .abortQuery             = NULL,
    .diagnostic             = NULL,
    .enteredMainFile        = NULL,
    .ppIncludedFile         = NULL,
    .importedASTFile        = NULL,
    .startedTranslationUnit = NULL,
    .indexDeclaration       = _indexerCallback,
    .indexEntityReference   = NULL
};

@implementation TQHeaderParser
@synthesize currentClass=_currentClass, functions=_functions, classes=_classes, literalConstants=_literalConstants,
            constants=_constants, protocols=_protocols, typedefs=_typedefs;

- (id)init
{
    if(!(self = [super init]))
        return nil;

    _index            = clang_createIndex(0, 1);
    assert(_index);
    _functions        = [NSMutableDictionary new];
    _literalConstants = [NSMutableDictionary new];
    _constants        = [NSMutableDictionary new];
    _classes          = [NSMutableDictionary new];
    _protocols        = [NSMutableDictionary new];
    _typedefs         = [NSMutableDictionary new];

    return self;
}

- (void)dealloc
{
    [_functions release];
    [_classes release];
    [_constants release];
    [_literalConstants release];
    [_protocols release];
    [_typedefs release];
    clang_disposeIndex(_index);

    [super dealloc];
}

- (id)parseHeader:(NSString *)aPath
{
    const char *args[] = { "-ObjC" };
    CXTranslationUnit translationUnit = clang_parseTranslationUnit(_index, [aPath fileSystemRepresentation], args, 1, NULL, 0,
                                                                   CXTranslationUnit_SkipFunctionBodies);
    if (!translationUnit) {
        NSLog(@"Couldn't parse header %@\n", aPath);
        return nil;
    }
    CXIndexAction action = clang_IndexAction_create(_index);
    int indexResult = clang_indexTranslationUnit(action,
                                                 (CXClientData)self,
                                                 &indexerCallbacks,
                                                 sizeof(indexerCallbacks),
                                                 CXIndexOpt_SuppressWarnings | CXIndexOpt_SuppressRedundantRefs,
                                                 translationUnit);
    clang_IndexAction_dispose(action);
    clang_disposeTranslationUnit(translationUnit);
    return TQValid;
}

- (id)parsePCH:(NSString *)aPath
{
    CXTranslationUnit translationUnit = clang_createTranslationUnit(_index, [aPath fileSystemRepresentation]);
    if (!translationUnit) {
        NSLog(@"Couldn't parse pch %@\n", aPath);
        return nil;
    }
    CXIndexAction action = clang_IndexAction_create(_index);
    int indexResult = clang_indexTranslationUnit(action,
                                                 (CXClientData)self,
                                                 &indexerCallbacks,
                                                 sizeof(indexerCallbacks),
                                                 CXIndexOpt_SuppressWarnings | CXIndexOpt_SuppressRedundantRefs,
                                                 translationUnit);
    clang_IndexAction_dispose(action);
    clang_disposeTranslationUnit(translationUnit);
    return TQValid;
}


- (TQNode *)entityNamed:(NSString *)aName
{
    id ret = [self functionNamed:aName];
    if(ret)
        return ret;
    return [self constantNamed:aName];
}

- (TQBridgedFunction *)functionNamed:(NSString *)aName
{
    return [_functions objectForKey:aName];
}

- (TQBridgedConstant *)constantNamed:(NSString *)aName
{
    id literal = [_literalConstants objectForKey:aName];
    if(literal)
        return literal;
    return [_constants objectForKey:aName];
}

- (TQBridgedClassInfo *)classNamed:(NSString *)aName
{
    return [_classes objectForKey:aName];
}


#pragma mark - Objective-C encoding generator

// Because the clang-c api doesn't allow us to access the "extended" encoding stuff inside libclang we must roll our own (It's less work than using the C++ api)
- (const char *)encodingForBlockPtrCursor:(CXCursor)cursor
{
    printf("    ..come on %s %s\n", clang_getCString(clang_getDeclObjCTypeEncoding(cursor)), clang_getCString(clang_getCursorSpelling(cursor)));
    NSMutableString *realEncoding = [NSMutableString stringWithString:@"<@"];
    clang_visitChildrenWithBlock(cursor, ^(CXCursor child, CXCursor parent) {
        //if(child.kind == CXCursor_ParmDecl)
            //return CXChildVisit_Recurse;
        const char *childEnc = [self encodingForCursor:child];
        printf("    %d %s -- '%s'\n", child.kind, childEnc, clang_getCString(clang_getCursorSpelling(child)));
        if(strstr(childEnc, "@?") == childEnc)
            [realEncoding appendFormat:@"%s", [self encodingForCursor:child]];
        else
            [realEncoding appendFormat:@"%s", childEnc];
        if(child.kind == 43) {
            CXType typeDef = clang_getCursorType(child);
            if(typeDef.kind == CXType_Typedef) { // Verify that it's in fact a typedef
                printf("      typedef!\n");
                CXType type = clang_getTypedefDeclUnderlyingType(child);
                printf("      underlying type: %p\n", type.kind);
            }
        }
        return CXChildVisit_Continue;
    });
    [realEncoding appendString:@">"];
    return [realEncoding UTF8String];
}

- (const char *)encodingForCursor:(CXCursor)cursor
{
    const char *vanillaEncoding = clang_getCString(clang_getDeclObjCTypeEncoding(cursor));
    CXCursorKind kind = cursor.kind;
    if(strstr(vanillaEncoding, "@?")) {
        // Contains a block argument so we need to manually create the encoding for it
        NSMutableString *realEncoding = [NSMutableString string];
        clang_visitChildrenWithBlock(cursor, ^(CXCursor child, CXCursor parent) {
            const char *childEnc = clang_getCString(clang_getDeclObjCTypeEncoding(child));
            if(strstr(childEnc, "@?") == childEnc)
                [realEncoding appendFormat:@"%s", [self encodingForBlockPtrCursor:child]];
            else
                [realEncoding appendFormat:@"%s", childEnc];
            return CXChildVisit_Continue;
        });
        return [realEncoding UTF8String];
    }
    return vanillaEncoding;
}
@end

@implementation TQBridgedClassInfo
@synthesize name=_name, instanceMethods=_instanceMethods, classMethods=_classMethods;
- (id)init
{
    if(!(self = [super init]))
        return nil;
    _instanceMethods = [NSMutableDictionary new];
    _classMethods    = [NSMutableDictionary new];
    return self;
}
- (void)dealloc
{
    [_name release];
    [_instanceMethods release];
    [_classMethods release];
    [super dealloc];
}
@end

@implementation TQBridgedConstant
@synthesize name=_name, encoding=_encoding;

+ (TQBridgedConstant *)constantWithName:(NSString *)aName encoding:(const char *)aEncoding;
{
    TQBridgedConstant *cnst = (TQBridgedConstant *)[self node];
    cnst.name = aName;
    cnst.encoding = aEncoding;
    return cnst;
}

- (void)dealloc
{
    [_name release];
    [super dealloc];
}

- (Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
    if(_global)
        return aBlock.builder->CreateLoad(_global);

    // With constants we just want to unbox them once and then keep that object around
    Module *mod = aProgram.llModule;
    Function *rootFunction = aProgram.rootBlock.function;
    IRBuilder<> rootBuilder(&rootFunction->getEntryBlock(), rootFunction->getEntryBlock().begin());
    Value *constant = mod->getOrInsertGlobal([_name UTF8String], [aProgram llvmTypeFromEncoding:_encoding]);
    constant = rootBuilder.CreateBitCast(constant, aProgram.llInt8PtrTy);
    Value *boxed = rootBuilder.CreateCall2(aProgram.TQBoxValue, constant, [aProgram getGlobalStringPtr:[NSString stringWithUTF8String:_encoding]
                                                                                           withBuilder:&rootBuilder]);
    _global = new GlobalVariable(*mod, aProgram.llInt8PtrTy, false, GlobalVariable::InternalLinkage,
                                 ConstantPointerNull::get(aProgram.llInt8PtrTy), [[@"TQBridgedConst_" stringByAppendingString:_name] UTF8String]);
    rootBuilder.CreateStore(boxed, _global);
    return aBlock.builder->CreateLoad(_global);
}
@end

@interface TQNodeBlock (Privates)
- (llvm::Value *)_generateBlockLiteralInProgram:(TQProgram *)aProgram parentBlock:(TQNodeBlock *)aParentBlock;
@end

@implementation TQBridgedFunction
@synthesize name=_name, encoding=_encoding;

+ (TQBridgedFunction *)functionWithName:(NSString *)aName encoding:(const char *)aEncoding

{
    return [[[self alloc] initWithName:aName encoding:aEncoding] autorelease];
}

- (id)initWithName:(NSString *)aName encoding:(const char *)aEncoding
{
    if(!(self = [super init]))
        return nil;

    self.name      = aName;
    self.encoding = aEncoding;

    TQIterateTypesInEncoding(aEncoding, ^(const char *type, NSUInteger size, NSUInteger align, BOOL *stop) {
        if(!_retType)
            _retType = [[NSString stringWithUTF8String:type] retain];
        else
            [_argTypes addObject:[NSString stringWithUTF8String:type]];
    });
    return self;
}

- (void)dealloc
{
    [_name release];
    [super dealloc];
}

- (NSUInteger)argumentCount
{
    return [_argTypes count];
}

// Compiles a a wrapper block for the function
// The reason we don't use TQBoxedObject is that when the function is known at compile time
// we can generate a far more efficient wrapper that doesn't rely on libffi
- (llvm::Function *)_generateInvokeInProgram:(TQProgram *)aProgram error:(NSError **)aoErr
{
    if(_function)
        return _function;

    llvm::PointerType *int8PtrTy = aProgram.llInt8PtrTy;

    // Build the invoke function
    std::vector<Type *> paramObjTypes(_argTypes.count+1, int8PtrTy);
    FunctionType* wrapperFunType = FunctionType::get(int8PtrTy, paramObjTypes, false);

    Module *mod = aProgram.llModule;

    const char *wrapperFunctionName = [[NSString stringWithFormat:@"__tq_wrapper_%@", _name] UTF8String];

    _function = Function::Create(wrapperFunType, GlobalValue::ExternalLinkage, wrapperFunctionName, mod);

    BasicBlock *entryBlock    = BasicBlock::Create(mod->getContext(), "entry", _function, 0);
    IRBuilder<> *entryBuilder = new IRBuilder<>(entryBlock);

    BasicBlock *callBlock    = BasicBlock::Create(mod->getContext(), "call", _function);
    IRBuilder<> *callBuilder = new IRBuilder<>(callBlock);

    BasicBlock *errBlock    = BasicBlock::Create(mod->getContext(), "invalidArgError", _function);
    IRBuilder<> *errBuilder = new IRBuilder<>(errBlock);

    // Load the block pointer argument (must do this before captures, which must be done before arguments in case a default value references a capture)
    llvm::Function::arg_iterator argumentIterator = _function->arg_begin();
    // Ignore the block pointer
    ++argumentIterator;


    // Load the arguments
    NSString *argTypeEncoding;
    Type *argType;
    std::vector<Type *> argTypes;
    std::vector<Value *> args;
    NSUInteger typeSize;
    BasicBlock  *nextBlock;
    IRBuilder<> *currBuilder, *nextBuilder;
    currBuilder = entryBuilder;

    Type *retType = [aProgram llvmTypeFromEncoding:[_retType UTF8String]];
    AllocaInst *resultAlloca = NULL;
    // If it's a void return we don't allocate a return buffer
    if(![_retType hasPrefix:@"v"])
        resultAlloca = entryBuilder->CreateAlloca(retType);

    TQGetSizeAndAlignment([_retType UTF8String], &typeSize, NULL);
    // Return doesn't fit in a register so we must pass an alloca before the function arguments
    // TODO: Make this cross platform
    BOOL returningOnStack = TQStructSizeRequiresStret(typeSize);
    if(returningOnStack) {
        argTypes.push_back(PointerType::getUnqual(retType));
        args.push_back(resultAlloca);
        retType = aProgram.llVoidTy;
    }

    NSMutableArray *byValArgIndices = [NSMutableArray array];
    if([_argTypes count] > 0) {
        Value *sentinel = entryBuilder->CreateLoad(mod->getOrInsertGlobal("TQSentinel", aProgram.llInt8PtrTy));
        for(int i = 0; i < [_argTypes count]; ++i)
        {
            argTypeEncoding = [_argTypes objectAtIndex:i];
            TQGetSizeAndAlignment([argTypeEncoding UTF8String], &typeSize, NULL);
            argType = [aProgram llvmTypeFromEncoding:[argTypeEncoding UTF8String]];
            // Larger structs should be passed as pointers to their location on the stack
            if(TQStructSizeRequiresStret(typeSize)) {
                argTypes.push_back(PointerType::getUnqual(argType));
                [byValArgIndices addObject:[NSNumber numberWithInt:i+1]]; // Add one to jump over retval
            } else
                argTypes.push_back(argType);

            IRBuilder<> startBuilder(&_function->getEntryBlock(), _function->getEntryBlock().begin());
            Value *unboxedArgAlloca = startBuilder.CreateAlloca(argType, NULL, [[NSString stringWithFormat:@"arg%d", i] UTF8String]);

            // If the value is a sentinel we've not been passed enough arguments => jump to error
            Value *notPassedCond = currBuilder->CreateICmpEQ(argumentIterator, sentinel);

            // Create the block for the next argument check (or set it to the call block)
            if(i == [_argTypes count]-1) {
                nextBlock = callBlock;
                nextBuilder = callBuilder;
            } else {
                nextBlock = BasicBlock::Create(mod->getContext(), [[NSString stringWithFormat:@"check%d", i] UTF8String], _function, callBlock);
                nextBuilder = new IRBuilder<>(nextBlock);
            }

            currBuilder->CreateCondBr(notPassedCond, errBlock, nextBlock);

            nextBuilder->CreateCall3(aProgram.TQUnboxObject,
                                     argumentIterator,
                                     [aProgram getGlobalStringPtr:argTypeEncoding withBuilder:nextBuilder],
                                     nextBuilder->CreateBitCast(unboxedArgAlloca, aProgram.llInt8PtrTy));
            if(TQStructSizeRequiresStret(typeSize))
                args.push_back(unboxedArgAlloca);
            else
                args.push_back(nextBuilder->CreateLoad(unboxedArgAlloca));

            ++argumentIterator;
            currBuilder = nextBuilder;
        }
    } else {
        currBuilder->CreateBr(callBlock);
    }

    // Populate the error block
    // TODO: Come up with a global error reporting mechanism and make this crash
    [aProgram insertLogUsingBuilder:errBuilder withStr:[@"Invalid number of arguments passed to " stringByAppendingString:_name]];
    errBuilder->CreateRet(ConstantPointerNull::get(int8PtrTy));

    // Populate call block
    FunctionType *funType = FunctionType::get(retType, argTypes, false);
    Function *function = aProgram.llModule->getFunction([_name UTF8String]);
    if(!function) {
        function = Function::Create(funType, GlobalValue::ExternalLinkage, [_name UTF8String], aProgram.llModule);
        function->setCallingConv(CallingConv::C);
        if(returningOnStack)
            function->addAttribute(1, Attribute::StructRet);
        for(NSNumber *idx in byValArgIndices) {
            function->addAttribute([idx intValue], Attribute::ByVal);
        }
    }

    Value *callResult = callBuilder->CreateCall(function, args);
    if([_retType hasPrefix:@"v"])
        callBuilder->CreateRet(ConstantPointerNull::get(aProgram.llInt8PtrTy));
    else if([_retType hasPrefix:@"@"])
        callBuilder->CreateRet(callResult);
    else {
        if(!returningOnStack)
            callBuilder->CreateStore(callResult, resultAlloca);
        Value *boxed = callBuilder->CreateCall2(aProgram.TQBoxValue,
                                                callBuilder->CreateBitCast(resultAlloca, int8PtrTy),
                                                [aProgram getGlobalStringPtr:_retType withBuilder:callBuilder]);
        // Retain/autorelease to force a TQBoxedObject move to the heap in case the returned value is stored in stack memory
        boxed = callBuilder->CreateCall(aProgram.objc_retainAutoreleaseReturnValue, boxed);
        callBuilder->CreateRet(boxed);
    }
    return _function;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
    if(![self _generateInvokeInProgram:aProgram error:aoErr])
        return NULL;

    Value *literal = (Value*)[self _generateBlockLiteralInProgram:aProgram parentBlock:aBlock];

    return literal;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<bridged function@ %@>", _name];
}
@end

