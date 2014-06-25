#import "TQHeaderParser.h"
#import "../../Runtime/TQBoxedObject.h"
#import "../CodeGen.h"
#import "../../Runtime/NSString+TQAdditions.h"
#import <objc/runtime.h>

using namespace llvm;

struct TQHeaderParserState {
    TQBridgedClassInfo *currentClass;
    NSMutableDictionary *functions;
    NSMutableDictionary *classes;
    NSMutableDictionary *literalConstants;
    NSMutableDictionary *constants;
    NSMutableDictionary *protocols;
};

#define EMPTY_PARSER_STATE ((struct TQHeaderParserState) { \
    nil, [NSMutableDictionary dictionary], [NSMutableDictionary dictionary], \
         [NSMutableDictionary dictionary], [NSMutableDictionary dictionary], \
         [NSMutableDictionary dictionary] })

static NSString *_prepareConstName(NSString *name)
{
    if([name hasPrefix:@"_"])
        return [NSString stringWithFormat:@"_%@", [[name substringFromIndex:1] stringByCapitalizingFirstLetter]];
    return [name stringByCapitalizingFirstLetter];
}

@interface TQHeaderParser ()
+ (const char *)_encodingForFunPtrCursor:(CXCursor)cursor;
+ (char *)_encodingForCursor:(CXCursor)cursor;
- (void)_parseTranslationUnit:(CXTranslationUnit)aTranslationUnit withState:(struct TQHeaderParserState *)aState;
- (void)_importParserState:(struct TQHeaderParserState *)aState;
- (BOOL)_writeParserState:(struct TQHeaderParserState *)aState toFile:(NSString *)aPath;
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
- (id)initWithCoder:(NSCoder *)aCoder
{
    if(!(self = [self init]))
        return nil;
    _functions        = [[aCoder decodeObject] retain];
    _classes          = [[aCoder decodeObject] retain];
    _literalConstants = [[aCoder decodeObject] retain];
    _constants        = [[aCoder decodeObject] retain];
    _protocols        = [[aCoder decodeObject] retain];
    return self;
}

- (id)parseHeader:(NSString *)aPath
{
    NSRange frameworkRange = [aPath rangeOfString:@".framework/"];
    NSString *frameworksPath = nil;
    if(frameworkRange.location != NSNotFound)
        frameworksPath = [[aPath substringToIndex:NSMaxRange(frameworkRange)] stringByDeletingLastPathComponent];

    // We create a temp TQPCH file so that future compiles go faster
    if(![aPath isAbsolutePath])
        aPath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:aPath];
    NSString *tempPath = [NSString stringWithFormat:@"/tmp/tranquil_pch/%@.tqpch", [aPath stringByDeletingPathExtension]];
    if([[NSFileManager defaultManager] fileExistsAtPath:tempPath])
        return [self parseTQPCH:tempPath];
    [[NSFileManager defaultManager] createDirectoryAtPath:[tempPath stringByDeletingLastPathComponent]
    withIntermediateDirectories:YES attributes:nil error:nil];
    const char *args[] = {
        "-x", "objective-c",
        "-isysroot", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.9.sdk/",
        "-I/usr/local/tranquil/llvm/lib/clang/3.2/include/", // TODO: Figure out why and if this is necessary, and if it is necessary, make it not hard-coded..
        frameworksPath ? [[@"-F" stringByAppendingString:frameworksPath] UTF8String] : nil
    };

    CXTranslationUnit translationUnit = clang_parseTranslationUnit(_index, [aPath fileSystemRepresentation], args, frameworksPath ? 6 : 5, NULL, 0,
                                                                   CXTranslationUnit_DetailedPreprocessingRecord|CXTranslationUnit_SkipFunctionBodies);
    if (!translationUnit) {
        TQLog(@"Couldn't parse header %@\n", aPath);
        return nil;
    }
    struct TQHeaderParserState parserState = EMPTY_PARSER_STATE;
    [self _parseTranslationUnit:translationUnit withState:&parserState];
    [self _importParserState:&parserState];

    // Cache to disk
    [self _writeParserState:&parserState toFile:tempPath];

    clang_disposeTranslationUnit(translationUnit);
    return TQValid;
}

- (void)_importParserState:(struct TQHeaderParserState *)aState
{
    [_functions addEntriesFromDictionary:aState->functions];
    [_classes addEntriesFromDictionary:aState->classes];
    [_literalConstants addEntriesFromDictionary:aState->literalConstants];
    [_constants addEntriesFromDictionary:aState->constants];
    [_protocols addEntriesFromDictionary:aState->protocols];
}
- (BOOL)_writeParserState:(struct TQHeaderParserState *)aState toFile:(NSString *)aPath
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
        aState->functions, @"functions",
        aState->classes, @"classes",
        aState->literalConstants, @"literalConstants",
        aState->constants, @"constants",
        aState->protocols, @"protocols", nil];
    return [NSKeyedArchiver archiveRootObject:dict toFile:aPath];
}

- (id)parseTQPCH:(NSString *)aPath
{
    NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithFile:aPath];
    struct TQHeaderParserState state = { nil,
        [dict objectForKey:@"functions"], [dict objectForKey:@"classes"],
        [dict objectForKey:@"literalConstants"], [dict objectForKey:@"constants"],
        [dict objectForKey:@"protocols"] };
    [self _importParserState:&state];

    return TQValid;
}

- (id)parsePCH:(NSString *)aPath
{
    CXTranslationUnit translationUnit = clang_createTranslationUnit(_index, [aPath fileSystemRepresentation]);
    if (!translationUnit) {
        TQLog(@"Couldn't parse pch %@\n", aPath);
        return nil;
    }
    struct TQHeaderParserState parserState = EMPTY_PARSER_STATE;
    [self _parseTranslationUnit:translationUnit withState:&parserState];
    [self _importParserState:&parserState];

    clang_disposeTranslationUnit(translationUnit);
    return TQValid;
}

- (void)_parseTranslationUnit:(CXTranslationUnit)aTranslationUnit withState:(struct TQHeaderParserState *)aState
{
    clang_visitChildrenWithBlock(clang_getTranslationUnitCursor(aTranslationUnit), ^(CXCursor cursor, CXCursor parent) {
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
                [aState->classes setObject:info forKey:nsName];
                aState->currentClass = info;
                [info release];
                goto recurse;
            } break;
            case CXCursor_ObjCSuperClassRef: {
                if(parent.kind == CXCursor_ObjCInterfaceDecl)
                    aState->currentClass.superclass = [aState->classes objectForKey:nsName];
            } break;
            case CXCursor_ObjCProtocolRef: {
                if(parent.kind == CXCursor_ObjCInterfaceDecl) {
                    TQBridgedClassInfo *protocolInfo = [aState->protocols objectForKey:nsName];
                    if(!protocolInfo)
                        break;
                    [aState->currentClass.instanceMethods addEntriesFromDictionary:protocolInfo.instanceMethods];
                    [aState->currentClass.classMethods    addEntriesFromDictionary:protocolInfo.classMethods];
                }
            } break;
            case CXCursor_ObjCCategoryDecl: {
                goto recurse;
            } break;
            case CXCursor_ObjCClassRef: {
                if(parent.kind == CXCursor_ObjCCategoryDecl)
                    aState->currentClass = [aState->classes objectForKey:nsName] ?: [_classes objectForKey:nsName];
            } break;
            case CXCursor_ObjCProtocolDecl: {
                TQBridgedClassInfo *info = [TQBridgedClassInfo new];
                [aState->protocols setObject:info forKey:nsName];
                aState->currentClass = info;
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
                    [aState->currentClass.classMethods    setObject:encoding forKey:selector];
                else
                    [aState->currentClass.instanceMethods setObject:encoding forKey:selector];
                free(encoding_);
            } break;
            case CXCursor_FunctionDecl: {
                // TODO: Support bridging variadic functions. Support or ignore inlined functions
                char *encoding         = [[self class] _encodingForCursor:cursor];
                TQBridgedFunction *fun = [TQBridgedFunction functionWithName:nsName encoding:encoding];
                [aState->functions setObject:fun
                                     forKey:_prepareConstName(nsName)];
                free(encoding);

            } break;
            case CXCursor_MacroDefinition: {
                CXSourceRange macroRange = clang_getCursorExtent(cursor);
                CXToken *tokens = 0;
                unsigned int tokenCount = 0;
                clang_tokenize(aTranslationUnit, macroRange, &tokens, &tokenCount);
                if(tokenCount >= 2) {
                    // TODO: Support string constants?
                    CXTokenKind tokenKind = clang_getTokenKind(tokens[1]);
                    CXString tokenSpelling = clang_getTokenSpelling(aTranslationUnit, tokens[1]);
                    const char *value = clang_getCString(tokenSpelling);
                    if(tokenKind == CXToken_Literal) {
                        [aState->literalConstants setObject:[TQNodeNumber nodeWithDouble:atof(value)] forKey:nsName];
                    } else if(tokenKind == CXToken_Identifier) { // Treat as alias
                        NSString *nsVal = [NSString stringWithUTF8String:value];
                        id existing = [aState->literalConstants objectForKey:nsVal] ?: [_literalConstants objectForKey:nsVal];
                        if(existing)
                            [aState->literalConstants setObject:existing forKey:nsName];
                    }
                    clang_disposeString(tokenSpelling);
                }
                clang_disposeTokens(aTranslationUnit, tokens, tokenCount);
            } break;
            case CXCursor_VarDecl: {
                char *encoding = [[self class] _encodingForCursor:cursor];
                [aState->constants setObject:[TQBridgedConstant constantWithName:nsName encoding:encoding]
                                      forKey:_prepareConstName(nsName)];
                free(encoding);
            } break;
            case CXCursor_EnumDecl: {
                goto recurse;
            } break;
            case CXCursor_EnumConstantDecl: {
                [aState->literalConstants setObject:[TQNodeNumber nodeWithDouble:clang_getEnumConstantDeclValue(cursor)]
                                             forKey:_prepareConstName(nsName)];
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


- (NSString *)classMethodTypeFromProtocols:(NSString *)aSelector
{
    NSString *selector = nil;
    for(TQBridgedClassInfo *protocol in [_protocols allValues]) {
        selector = [protocol.classMethods objectForKey:aSelector];
        if(selector) break;
    }
    return selector;
}
- (NSString *)instanceMethodTypeFromProtocols:(NSString *)aSelector
{
    NSString *selector = nil;
    for(TQBridgedClassInfo *protocol in [_protocols allValues]) {
        selector = [protocol.instanceMethods objectForKey:aSelector];
        if(selector) break;
    }
    return selector;
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
        TQAssert(NO, @"PANIC (%s: %s)",  clang_getCString(clang_getCursorSpelling(cursor)), clang_getCString(clang_getTypeKindSpelling(type.kind)));

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
        // Contains  block argument(s) so we need to manually create the encodings for them
        NSMutableArray *typeComponents = [NSMutableArray array];
        TQIterateTypesInEncoding(vanillaEncoding, ^(const char *type, NSUInteger size, NSUInteger align, BOOL *stop) {
            const char *nextTy = TQGetSizeAndAlignment(type, NULL, NULL);
            if(nextTy)
                [typeComponents addObject:[[[NSString alloc] initWithBytes:(void*)type length:nextTy - type encoding:NSUTF8StringEncoding] autorelease]];
            else
                [typeComponents addObject:[NSString stringWithUTF8String:type]];
        });

        __block int i = 0, j = 0;
        clang_visitChildrenWithBlock(cursor, ^(CXCursor child, CXCursor parent) {
            CXString childEnc_  = clang_getDeclObjCTypeEncoding(child);
            const char *childEnc = clang_getCString(childEnc_);
            BOOL isBlock = strstr(childEnc, "@?") == childEnc;
            if(isBlock || strstr(childEnc, "^?") == childEnc) {
                NSUInteger idx;
                if(isBlock) {
                    idx = [typeComponents indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
                        return [obj hasPrefix:@"@?"];
                    }];
                } else {
                    idx = [typeComponents indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
                        return [obj hasPrefix:@"^?"];
                    }];
                }
                NSAssert(idx != NSNotFound, @"Panic in header parser");
                const char *encoding = [[self class] _encodingForFunPtrCursor:child];
                [typeComponents replaceObjectAtIndex:idx withObject:[NSString stringWithUTF8String:encoding]];
            }
            clang_disposeString(childEnc_);
            return CXChildVisit_Continue;
        });
        NSString *realEncoding = [typeComponents componentsJoinedByString:@""];
        clang_disposeString(cxvanillaEncoding);
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

- (id)initWithCoder:(NSKeyedArchiver *)aCoder
{
    if(!(self = [super init]))
        return nil;
    _name            = [[aCoder decodeObjectForKey:@"name"] retain];
    _superclass      = [[aCoder decodeObjectForKey:@"superclass"] retain];
    // Defer decoding the expensive dictionaries until they're actually used
    _decoder         = [aCoder retain];
    return self;
}
- (void)encodeWithCoder:(NSKeyedArchiver  *)aCoder
{
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_superclass forKey:@"superclass"];
    [aCoder encodeObject:_classMethods forKey:@"classMethods"];
    [aCoder encodeObject:_instanceMethods forKey:@"instanceMethods"];
}

- (NSMutableDictionary *)classMethods
{
    if(!_classMethods)
        _classMethods = [_decoder decodeObjectForKey:@"classMethods"] ?: [NSMutableDictionary new];
    return _classMethods;
}
- (NSMutableDictionary *)instanceMethods
{
    if(!_instanceMethods)
        _instanceMethods = [_decoder decodeObjectForKey:@"instanceMethods"] ?: [NSMutableDictionary new];
    return _instanceMethods;
}

- (NSString *)typeForInstanceMethod:(NSString *)aSelector
{
    NSString *enc = [self.instanceMethods objectForKey:aSelector];
    if(enc)
        return enc;
    return [_superclass typeForInstanceMethod:aSelector];
}

- (NSString *)typeForClassMethod:(NSString *)aSelector
{
    NSString *enc = [self.classMethods objectForKey:aSelector];
    if(enc)
        return enc;
    return [_superclass typeForClassMethod:aSelector];
}

- (void)dealloc
{
    [_name release];
    [_instanceMethods release];
    [_classMethods release];
    [_decoder release];
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

- (id)initWithCoder:(NSCoder *)aCoder
{
    if(!(self = [super init]))
        return nil;
    _name     = [[aCoder decodeObject] retain];
    _encoding = strdup((char *)[aCoder decodeBytesWithReturnedLength:NULL]);
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_name];
    [aCoder encodeBytes:_encoding length:strlen(_encoding)+1];
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
    Type *constType = [aProgram llvmTypeFromEncoding:_encoding];
    Value *constant = mod->getOrInsertGlobal([_name UTF8String], constType);
    NSString *nsEncoding = [NSString stringWithUTF8String:_encoding];
    if(*_encoding == _C_PTR || *_encoding == _C_CHARPTR) {
        // If it is a pointer we need to pass a pointer to it
        constant = rootBuilder.CreateBitCast(constant, aProgram.llInt8PtrTy);
        Value *ref = rootBuilder.CreateAlloca(aProgram.llInt8PtrTy);
        rootBuilder.CreateStore(constant, ref);
        constant = rootBuilder.CreateBitCast(ref, aProgram.llInt8PtrTy);
    } else {
        constant = rootBuilder.CreateBitCast(constant, aProgram.llInt8PtrTy);
    }
    Value *boxed = rootBuilder.CreateCall2(aProgram.TQBoxValue, constant, [aProgram getGlobalStringPtr:nsEncoding
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

    return self;
}

- (id)initWithCoder:(NSCoder *)aCoder
{
    if(!(self = [super init]))
        return nil;
    _name     = [[aCoder decodeObject] retain];
    _encoding = strdup((char *)[aCoder decodeBytesWithReturnedLength:NULL]);
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_name];
    [aCoder encodeBytes:_encoding length:strlen(_encoding)+1];
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

- (void)_computeReturnAndArgTypes
{
    // To avoid performing this work for bridged functions that are never used, we do it the first time it's used
    if(!_argTypes) {
        _argTypes = [NSMutableArray new];
        TQIterateTypesInEncoding(_encoding, ^(const char *type, NSUInteger size, NSUInteger align, BOOL *stop) {
            if(!_retType)
                _retType = [NSString stringWithUTF8String:type];
            else
                [_argTypes addObject:[NSString stringWithUTF8String:type]];
        });
    }
}


// Compiles a a wrapper block for the function
// The reason we don't use TQBoxedObject is that when the function is known at compile time
// we can generate a far more efficient wrapper that doesn't rely on libffi
- (llvm::Function *)_generateInvokeInProgram:(TQProgram *)aProgram root:(TQNodeRootBlock *)aRoot block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
    if(_function)
        return _function;

    [self _computeReturnAndArgTypes];

    llvm::PointerType *int8PtrTy = aProgram.llInt8PtrTy;

    // Build the invoke function
    std::vector<Type *> paramObjTypes(_argTypes.count+1, int8PtrTy);
    FunctionType* wrapperFunType = FunctionType::get(int8PtrTy, paramObjTypes, false);

    Module *mod = aProgram.llModule;

    const char *wrapperFunctionName = [[NSString stringWithFormat:@"__tranquil_wrapper_%@", _name] UTF8String];

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
    Attributes byvalAttr = Attributes::get(mod->getContext(), ArrayRef<Attributes::AttrVal>(Attributes::ByVal));
    if(!function) {
        function = Function::Create(funType, GlobalValue::ExternalLinkage, [_name UTF8String], aProgram.llModule);
        function->setCallingConv(CallingConv::C);
        if(returningOnStack) {
            Attributes structRetAttr = Attributes::get(mod->getContext(), ArrayRef<Attributes::AttrVal>(Attributes::StructRet));
            function->addAttribute(1, structRetAttr);
        }
        [byValArgIndices enumerateIndexesWithOptions:0 usingBlock:^(NSUInteger idx, BOOL *stop) {
            function->addAttribute(returningOnStack ? idx+1 : idx, byvalAttr);
        }];
    }

    CallInst *call = callBuilder.CreateCall(function, args);
    [byValArgIndices enumerateIndexesWithOptions:0 usingBlock:^(NSUInteger idx, BOOL *stop) {
        call->addAttribute(returningOnStack ? idx+1 : idx, byvalAttr);
    }];
    const char *retTypeCStr = [_retType UTF8String];
    if([_retType hasPrefix:@"v"])
        callBuilder.CreateRet(ConstantPointerNull::get(aProgram.llInt8PtrTy));
    else if([_retType hasPrefix:@"@"] || TYPE_IS_TOLLFREE(retTypeCStr))
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
    Module *mod = aProgram.llModule;
    NSString *globalName = [NSString stringWithFormat:@"__boxed_%@", _name];
    Value *global = mod->getGlobalVariable([globalName UTF8String], true);
    if(!global) {
        global = new GlobalVariable(*mod, aProgram.llInt8PtrTy, false, GlobalVariable::InternalLinkage,
                                    ConstantPointerNull::get(aProgram.llInt8PtrTy), [globalName UTF8String]);
        Value *fun = mod->getOrInsertGlobal([_name UTF8String], aProgram.llInt8Ty);

        Function *rootFunction = aRoot.function;
        IRBuilder<> rootBuilder(&rootFunction->getEntryBlock(), rootFunction->getEntryBlock().begin());

        Value *boxed = rootBuilder.CreateCall2(aProgram.TQBoxValue, fun,
                        [aProgram getGlobalStringPtr:[NSString stringWithFormat:@"<^%s>", _encoding] withBuilder:&rootBuilder]);
        boxed = rootBuilder.CreateCall(aProgram.objc_retain, boxed);
        rootBuilder.CreateStore(boxed, global);
    }
    return aBlock.builder->CreateLoad(global);

    // Disabled until native calling conventions are a 100% (begrudgingly using libffi fallback for now)
#if 0
    if(![self _generateInvokeInProgram:aProgram root:aRoot block:aBlock error:aoErr])
        return NULL;

    Value *literal = (Value*)[self _generateBlockLiteralInProgram:aProgram parentBlock:aBlock root:aRoot];

    return literal;
#endif
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<bridged function@ %@>", _name];
}
@end
