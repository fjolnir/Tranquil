#import "TQHeaderParser.h"
#import "../CodeGen.h"
#import "../../Runtime/NSString+TQAdditions.h"
#import <objc/runtime.h>

using namespace llvm;

static NSString *_prepareConstName(NSString *name)
{
    if([name hasPrefix:@"_"])
        return [NSString stringWithFormat:@"_%@", [[name substringFromIndex:1] stringByCapitalizingFirstLetter]];
    return [name stringByCapitalizingFirstLetter];
}

@interface TQHeaderParser ()
+ (const char *)_encodingForFunPtrCursor:(CXCursor)cursor;
+ (char *)_encodingForCursor:(CXCursor)cursor;
- (void)_parseTranslationUnit:(CXTranslationUnit)translationUnit;
@end

@implementation TQHeaderParser
- (id)init
{
    if(!(self = [super init]))
        return nil;

    _functions        = [NSMutableDictionary new];
    _literalConstants = [NSMutableDictionary new];
    _constants        = [NSMutableDictionary new];
    _classes          = [NSMutableDictionary new];
    _protocols        = [NSMutableDictionary new];
    _index            = clang_createIndex(0, 1);

    return self;
}

- (void)dealloc
{
    [_functions release];
    [_classes release];
    [_constants release];
    [_literalConstants release];
    [_protocols release];
    clang_disposeIndex(_index);

    [super dealloc];
}

- (id)parseHeader:(NSString *)aPath
{
    NSRange frameworkRange = [aPath rangeOfString:@".framework/"];
    NSString *frameworksPath = nil;
    if(frameworkRange.location != NSNotFound)
        frameworksPath = [[aPath substringToIndex:NSMaxRange(frameworkRange)] stringByDeletingLastPathComponent];

    const char *args[] = { "-x", "objective-c", frameworksPath ? [[@"-F" stringByAppendingString:frameworksPath] UTF8String] : nil  };
    CXTranslationUnit translationUnit = clang_parseTranslationUnit(_index, [aPath fileSystemRepresentation], args, frameworksPath ? 3 : 2, NULL, 0,
                                                                   CXTranslationUnit_DetailedPreprocessingRecord|CXTranslationUnit_SkipFunctionBodies);
    if (!translationUnit) {
        TQLog(@"Couldn't parse header %@\n", aPath);
        return nil;
    }
    [self _parseTranslationUnit:translationUnit];
    clang_disposeTranslationUnit(translationUnit);
    return TQValid;
}

- (id)parsePCH:(NSString *)aPath
{
    CXTranslationUnit translationUnit = clang_createTranslationUnit(_index, [aPath fileSystemRepresentation]);
    if (!translationUnit) {
        TQLog(@"Couldn't parse pch %@\n", aPath);
        return nil;
    }
    [self _parseTranslationUnit:translationUnit];
    clang_disposeTranslationUnit(translationUnit);
    return TQValid;
}

- (void)_parseTranslationUnit:(CXTranslationUnit)translationUnit
{
    clang_visitChildrenWithBlock(clang_getTranslationUnitCursor(translationUnit), ^(CXCursor cursor, CXCursor parent) {
        CXString spelling = clang_getCursorSpelling(cursor);
        const char *name = clang_getCString(spelling);
        if(!name)
            return CXChildVisit_Continue;
        NSString *nsName = [NSString stringWithUTF8String:name];
        @try {
        switch(cursor.kind) {
            case CXCursor_ObjCInterfaceDecl: {
                TQBridgedClassInfo *info = [TQBridgedClassInfo new];
                info.name = nsName;
                [_classes setObject:info forKey:nsName];
                _currentClass = info;
                [info release];
                goto recurse;
            } break;
            case CXCursor_ObjCSuperClassRef: {
                if(parent.kind == CXCursor_ObjCInterfaceDecl)
                    _currentClass.superclass = [_classes objectForKey:nsName];
            } break;
            case CXCursor_ObjCProtocolRef: {
                if(parent.kind == CXCursor_ObjCInterfaceDecl) {
                    TQBridgedClassInfo *protocolInfo = [_protocols objectForKey:nsName];
                    if(!protocolInfo)
                        break;
                    [_currentClass.instanceMethods addEntriesFromDictionary:protocolInfo.instanceMethods];
                    [_currentClass.classMethods    addEntriesFromDictionary:protocolInfo.classMethods];
                }
            } break;
            case CXCursor_ObjCCategoryDecl: {
                goto recurse;
            } break;
            case CXCursor_ObjCClassRef: {
                if(parent.kind == CXCursor_ObjCCategoryDecl)
                    _currentClass = [_classes objectForKey:nsName];
            } break;
            case CXCursor_ObjCProtocolDecl: {
                 TQBridgedClassInfo *info = [TQBridgedClassInfo new];
                [_protocols setObject:info forKey:nsName];
                _currentClass = info;
                [info release];
                goto recurse;
            } break;
            case CXCursor_ObjCClassMethodDecl:
            case CXCursor_ObjCInstanceMethodDecl: {
                BOOL isClassMethod    = cursor.kind == CXCursor_ObjCClassMethodDecl;
                NSString *selector    = nsName;
                char *encoding_       = [[self class] _encodingForCursor:cursor];
                NSString *encoding    = [NSString stringWithUTF8String:encoding_];
                if(isClassMethod)
                    [_currentClass.classMethods    setObject:encoding forKey:selector];
                else
                    [_currentClass.instanceMethods setObject:encoding forKey:selector];
                free(encoding_);
            } break;
            case CXCursor_FunctionDecl: {
                // TODO: Support bridging variadic functions. Support or ignore inlined functions
                char *encoding         = [[self class] _encodingForCursor:cursor];
                TQBridgedFunction *fun = [TQBridgedFunction functionWithName:nsName encoding:encoding];
                [_functions setObject:fun
                               forKey:_prepareConstName(nsName)];
                free(encoding);

            } break;
            case CXCursor_MacroDefinition: {
                CXSourceRange macroRange = clang_getCursorExtent(cursor);
                CXToken *tokens = 0;
                unsigned int tokenCount = 0;
                clang_tokenize(translationUnit, macroRange, &tokens, &tokenCount);
                if(tokenCount >= 2) {
                    // TODO: Support string constants?
                    CXTokenKind tokenKind = clang_getTokenKind(tokens[1]);
                    CXString tokenSpelling = clang_getTokenSpelling(translationUnit, tokens[1]);
                    const char *value = clang_getCString(tokenSpelling);
                    if(tokenKind == CXToken_Literal) {
                        [_literalConstants setObject:[TQNodeNumber nodeWithDouble:atof(value)] forKey:nsName];
                    } else if(tokenKind == CXToken_Identifier) { // Treat as alias
                        id existing = [_literalConstants objectForKey:[NSString stringWithUTF8String:value]];
                        if(existing)
                            [_literalConstants setObject:existing forKey:nsName];
                    }
                    clang_disposeString(tokenSpelling);
                }
                clang_disposeTokens(translationUnit, tokens, tokenCount);
            } break;
            case CXCursor_VarDecl: {
                char *encoding = [[self class] _encodingForCursor:cursor];
                [_constants setObject:[TQBridgedConstant constantWithName:nsName encoding:encoding]
                               forKey:_prepareConstName(nsName)];
                free(encoding);
            } break;
            case CXCursor_EnumDecl: {
                goto recurse;
            } break;
            case CXCursor_EnumConstantDecl: {
                [_literalConstants setObject:[TQNodeNumber nodeWithDouble:clang_getEnumConstantDeclValue(cursor)]
                                      forKey:nsName];
            } break;
            // Ignored
            case CXCursor_StructDecl:
            case CXCursor_TypedefDecl:
            case CXCursor_UnexposedAttr:
            case CXCursor_TypeRef:
            case CXCursor_ObjCIvarDecl:
            case CXCursor_ObjCPropertyDecl:
            case CXCursor_MacroExpansion:
            case CXCursor_InclusionDirective:
            case CXCursor_UnionDecl:
            break;
            default:
                TQLog(@"Unhandled Objective-C entity: %s of type %d %s = %s\n", name, cursor.kind, clang_getCString(clang_getCursorKindSpelling(cursor.kind)),
                      clang_getCString(clang_getTypeKindSpelling(clang_getCursorType(cursor).kind)));
                break;
        }
        clang_disposeString(spelling);
        return CXChildVisit_Continue;

        recurse:
            clang_disposeString(spelling);
            return CXChildVisit_Recurse;
        } @catch(NSException *e) {
            NSLog(@"Error parsing entity %s! %@", name, e);
    }

    });
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

// Because the clang-c api doesn't allow us to access the "extended" encoding stuff inside libclang we must roll our own (From what I can tell, it's less work than using the C++ api)
+ (const char *)_encodingForFunPtrCursor:(CXCursor)cursor
{
    CXType type = clang_getCursorType(cursor);
    NSMutableString *realEncoding = [NSMutableString stringWithString:@"<"];
    // Resolve any typedef to it's original type
    while(type.kind == CXType_Typedef) {
        cursor = clang_getTypeDeclaration(type);
        type = clang_getTypedefDeclUnderlyingType(cursor);
    }

    if(type.kind == CXType_BlockPointer)
        [realEncoding appendString:@"@"];
    else if(type.kind == CXType_Pointer)
        [realEncoding appendString:@"^"];
    else
        TQAssert(nil, @"PANIC (%s: %s)",  clang_getCString(clang_getCursorSpelling(cursor)), clang_getCString(clang_getTypeKindSpelling(type.kind)));

    __block BOOL isFirstChild = YES;
    clang_visitChildrenWithBlock(cursor, ^(CXCursor child, CXCursor parent) {
        // If the function returns void, we don't have a node for the return type
        if(isFirstChild && child.kind == CXCursor_ParmDecl)
            [realEncoding appendString:@"v"];
        isFirstChild = NO;

        char *childEnc = [[self class] _encodingForCursor:child];
        if(!childEnc || strlen(childEnc) == 0) {
            CXType type = clang_getCursorType(child);
            CXTypeKind kind = type.kind;
            if(kind == CXType_Enum)
                [realEncoding appendFormat:@"i"];
        }
        else if(strstr(childEnc, "@?") == childEnc || strstr(childEnc, "^?") == childEnc)
            [realEncoding appendFormat:@"%s", [[self class] _encodingForFunPtrCursor:child]];
        else
            [realEncoding appendFormat:@"%s", childEnc];
        free(childEnc);
        return CXChildVisit_Continue;
    });
    if(isFirstChild) // No children => void return and no args
        [realEncoding appendString:@"v"];
    [realEncoding appendString:@">"];
    return [realEncoding UTF8String];
}

// You are responsible for freeing the returned string
+ (char *)_encodingForCursor:(CXCursor)cursor
{
    CXString cxvanillaEncoding = clang_getDeclObjCTypeEncoding(cursor);
    char *vanillaEncoding = (char*)clang_getCString(cxvanillaEncoding);
    CXCursorKind kind = cursor.kind;
    if(strstr(vanillaEncoding, "@?") || strstr(vanillaEncoding, "^?")) {
        clang_disposeString(cxvanillaEncoding);
        // Contains a block argument so we need to manually create the encoding for it
        NSMutableString *realEncoding = [NSMutableString string];
        __block BOOL isFirstChild = YES;
        clang_visitChildrenWithBlock(cursor, ^(CXCursor child, CXCursor parent) {
            if(child.kind == CXCursor_UnexposedAttr)
                return CXChildVisit_Continue;
            if(isFirstChild && child.kind == CXCursor_ParmDecl && (kind == CXCursor_FunctionDecl || kind == CXCursor_ObjCForCollectionStmt
                                                                   || kind == CXIdxEntity_ObjCClassMethod || kind == CXIdxEntity_ObjCInstanceMethod)) {
                [realEncoding appendString:@"v"];
            }
            isFirstChild = NO;
            CXString childEnc_  = clang_getDeclObjCTypeEncoding(child);
            const char *childEnc = clang_getCString(childEnc_);
            if(strstr(childEnc, "@?") == childEnc || strstr(childEnc, "^?") == childEnc) {
                [realEncoding appendFormat:@"%s", [[self class] _encodingForFunPtrCursor:child]];
            } else
                [realEncoding appendFormat:@"%s", childEnc];
            clang_disposeString(childEnc_);
            return CXChildVisit_Continue;
        });
        return strdup([realEncoding UTF8String]);
    }
    vanillaEncoding = strdup(vanillaEncoding);
    clang_disposeString(cxvanillaEncoding);
    return vanillaEncoding;
}
@end

@implementation TQBridgedClassInfo
@synthesize name=_name, instanceMethods=_instanceMethods, classMethods=_classMethods, superclass=_superclass;
- (id)init
{
    if(!(self = [super init]))
        return nil;
    _instanceMethods = [NSMutableDictionary new];
    _classMethods    = [NSMutableDictionary new];
    return self;
}

- (NSString *)typeForInstanceMethod:(NSString *)aSelector
{
    NSString *enc = [_instanceMethods objectForKey:aSelector];
    if(enc)
        return enc;
    return [_superclass typeForInstanceMethod:aSelector];
}

- (NSString *)typeForClassMethod:(NSString *)aSelector
{
    NSString *enc = [_classMethods objectForKey:aSelector];
    if(enc)
        return enc;
    return [_superclass typeForClassMethod:aSelector];
}

- (void)dealloc
{
    [_name release];
    [_instanceMethods release];
    [_classMethods release];
    [super dealloc];
}
@end

@interface TQBridgedConstant ()
@property(readwrite) char *encoding;
@end

@implementation TQBridgedConstant
@synthesize name=_name, encoding=_encoding;

+ (TQBridgedConstant *)constantWithName:(NSString *)aName encoding:(const char *)aEncoding;
{
    TQBridgedConstant *cnst = (TQBridgedConstant *)[self node];
    cnst.name = aName;
    cnst.encoding = strdup((char *)aEncoding);
    return cnst;
}

- (void)dealloc
{
    if(_encoding)
        free(_encoding);
    [_name release];
    [super dealloc];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    if(_global)
        return aBlock.builder->CreateLoad(_global);

    // With constants we just want to unbox them once and then keep that object around
    Module *mod = aProgram.llModule;
    Function *rootFunction = aRoot.function;
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
- (llvm::Value *)_generateBlockLiteralInProgram:(TQProgram *)aProgram parentBlock:(TQNodeBlock *)aParentBlock root:(TQNodeRootBlock *)aRoot;
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
    _name     = [aName retain];
    _encoding = strdup(aEncoding);
    _argTypes = [NSMutableArray new];
    TQIterateTypesInEncoding(_encoding, ^(const char *type, NSUInteger size, NSUInteger align, BOOL *stop) {
        if(!_retType)
            _retType = [[NSString stringWithUTF8String:type] retain];
        else
            [_argTypes addObject:[NSString stringWithUTF8String:type]];
    });

    return self;
}

- (void)dealloc
{
    if(_encoding)
        free(_encoding);
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
- (llvm::Function *)_generateInvokeInProgram:(TQProgram *)aProgram root:(TQNodeRootBlock *)aRoot block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
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
    IRBuilder<> entryBuilder(entryBlock);

    BasicBlock *callBlock     = BasicBlock::Create(mod->getContext(), "call", _function);
    IRBuilder<> callBuilder(callBlock);

    BasicBlock *errBlock      = BasicBlock::Create(mod->getContext(), "invalidArgError", _function);
    IRBuilder<> errBuilder(errBlock);

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
    currBuilder = &entryBuilder;

    Type *retType = [aProgram llvmTypeFromEncoding:[_retType UTF8String]];
    AllocaInst *resultAlloca = NULL;
    // If it's a void return we don't allocate a return buffer
    if(![_retType hasPrefix:@"v"])
        resultAlloca = entryBuilder.CreateAlloca(retType);

    TQGetSizeAndAlignment([_retType UTF8String], &typeSize, NULL);
    // Return doesn't fit in a register so we must pass an alloca before the function arguments
    // TODO: Make this cross platform
    BOOL returningOnStack = TQStructSizeRequiresStret(typeSize);
    if(returningOnStack) {
        argTypes.push_back(PointerType::getUnqual(retType));
        args.push_back(resultAlloca);
        retType = aProgram.llVoidTy;
    }

    NSMutableIndexSet *byValArgIndices = [NSMutableIndexSet indexSet];
    std::vector<IRBuilder <>*> argCheckBuilders;
    if([_argTypes count] > 0) {
        Value *sentinel = entryBuilder.CreateLoad(mod->getOrInsertGlobal("TQNothing", aProgram.llInt8PtrTy));
        for(int i = 0; i < [_argTypes count]; ++i)
        {
            argTypeEncoding = [_argTypes objectAtIndex:i];
            TQGetSizeAndAlignment([argTypeEncoding UTF8String], &typeSize, NULL);
            argType = [aProgram llvmTypeFromEncoding:[argTypeEncoding UTF8String]];
            SmallVector<llvm::Value*, 8> values;
            SmallVector<llvm::Type*, 8> types;
            //BOOL expandable = [aProgram expandLLVMValue:NULL // TODO
                                                 //ofType:argType
                                                     //to:&values
                                                //ofTypes:&types
                                            //forFunction:_function
                                           //usingBuilder:currBuilder];
            //NSLog(@"%@ Expandable? %d", argTypeEncoding, expandable);
            // Larger structs should be passed as pointers to their location on the stack
            if(TQStructSizeRequiresStret(typeSize)) {
                argTypes.push_back(PointerType::getUnqual(argType));
                [byValArgIndices addIndex:i+1]; // Add one to jump over retval
            } else
                argTypes.push_back(argType);

            IRBuilder<> startBuilder(&_function->getEntryBlock(), _function->getEntryBlock().begin());
            Value *unboxedArgAlloca = startBuilder.CreateAlloca(argType, NULL, [[NSString stringWithFormat:@"arg%d", i] UTF8String]);

            // If the value is a sentinel we've not been passed enough arguments => jump to error
            Value *notPassedCond = currBuilder->CreateICmpEQ(argumentIterator, sentinel);

            // Create the block for the next argument check (or set it to the call block)
            if(i == [_argTypes count]-1) {
                nextBlock = callBlock;
                nextBuilder = &callBuilder;
            } else {
                nextBlock = BasicBlock::Create(mod->getContext(), [[NSString stringWithFormat:@"check%d", i] UTF8String], _function, callBlock);
                nextBuilder = new IRBuilder<>(nextBlock);
                argCheckBuilders.push_back(nextBuilder);
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
    [aProgram insertLogUsingBuilder:&errBuilder withStr:[@"Invalid number of arguments passed to " stringByAppendingString:_name]];
    errBuilder.CreateRet(ConstantPointerNull::get(int8PtrTy));

    // Populate call block
    FunctionType *funType = FunctionType::get(retType, argTypes, false);
    Function *function = aProgram.llModule->getFunction([_name UTF8String]);
    if(!function) {
        function = Function::Create(funType, GlobalValue::ExternalLinkage, [_name UTF8String], aProgram.llModule);
        function->setCallingConv(CallingConv::C);
        if(returningOnStack)
            function->addAttribute(1, Attribute::StructRet);
        [byValArgIndices enumerateIndexesWithOptions:0 usingBlock:^(NSUInteger idx, BOOL *stop) {
            function->addAttribute(returningOnStack ? idx+1 : idx, Attribute::ByVal);
        }];
    }

    CallInst *call = callBuilder.CreateCall(function, args);
    [byValArgIndices enumerateIndexesWithOptions:0 usingBlock:^(NSUInteger idx, BOOL *stop) {
        call->addAttribute(returningOnStack ? idx+1 : idx, Attribute::ByVal);
    }];
    if([_retType hasPrefix:@"v"])
        callBuilder.CreateRet(ConstantPointerNull::get(aProgram.llInt8PtrTy));
    else if([_retType hasPrefix:@"@"] || [_retType hasPrefix:@"^{__CF"] || [_retType hasPrefix:@"^{__AX"])
        callBuilder.CreateRet(call);
    else {
        if(!returningOnStack)
            callBuilder.CreateStore(call, resultAlloca);
        Value *boxed = callBuilder.CreateCall2(aProgram.TQBoxValue,
                                               callBuilder.CreateBitCast(resultAlloca, int8PtrTy),
                                               [aProgram getGlobalStringPtr:_retType withBuilder:&callBuilder]);
        // Retain/autorelease to force a TQBoxedObject move to the heap in case the returned value is stored in stack memory
        boxed = callBuilder.CreateCall(aProgram.objc_retainAutoreleaseReturnValue, boxed);
        callBuilder.CreateRet(boxed);
    }

    for(int i = 0; i < argCheckBuilders.size(); ++i) {
        delete argCheckBuilders[i];
    }
    return _function;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    if(![self _generateInvokeInProgram:aProgram root:aRoot block:aBlock error:aoErr])
        return NULL;

    Value *literal = (Value*)[self _generateBlockLiteralInProgram:aProgram parentBlock:aBlock root:aRoot];

    return literal;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<bridged function@ %@>", _name];
}
@end
