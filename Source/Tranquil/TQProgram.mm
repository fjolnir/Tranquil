#import "TQProgram.h"
#import "TQDebug.h"
#import "TQProgram+Private.h"
#import "CodeGen/TQNode.h"
#import <llvm/Transforms/IPO/PassManagerBuilder.h>
#import <llvm/Target/TargetData.h>
#import <mach/mach_time.h>
#import "Runtime/TQRuntime.h"
#import "BridgeSupport/TQBoxedObject.h"
#import "CodeGen/Processors/TQProcessor.h"
#import <objc/runtime.h>
#import <objc/message.h>
extern "C" {
#import "parse.m"
}

# include <llvm/Module.h>
# include <llvm/DerivedTypes.h>
# include <llvm/Constants.h>
# include <llvm/CallingConv.h>
# include <llvm/Instructions.h>
# include <llvm/PassManager.h>
# include <llvm/Analysis/Verifier.h>
# include <llvm/Target/TargetData.h>
# include <llvm/ExecutionEngine/JIT.h>
# include <llvm/ExecutionEngine/JITMemoryManager.h>
# include <llvm/ExecutionEngine/JITEventListener.h>
# include <llvm/ExecutionEngine/GenericValue.h>
# include <llvm/Target/TargetData.h>
# include <llvm/Target/TargetMachine.h>
# include <llvm/Target/TargetOptions.h>
# include <llvm/Transforms/Scalar.h>
# include <llvm/Transforms/IPO.h>
# include <llvm/Support/raw_ostream.h>
# if !defined(LLVM_TOT)
#  include <llvm/Support/system_error.h>
# endif
# include <llvm/Support/PrettyStackTrace.h>
# include <llvm/Support/MemoryBuffer.h>
# include <llvm/Intrinsics.h>
# include <llvm/Bitcode/ReaderWriter.h>
# include <llvm/LLVMContext.h>
# include "llvm/ADT/Statistic.h"

using namespace llvm;

NSString * const kTQSyntaxErrorException = @"TQSyntaxErrorException";

@implementation TQProgram
@synthesize name=_name, llModule=_llModule, shouldShowDebugInfo=_shouldShowDebugInfo,
            objcParser=_objcParser, searchPaths=_searchPaths, allowedFileExtensions=_allowedFileExtensions;
@synthesize llVoidTy=_llVoidTy, llInt8Ty=_llInt8Ty, llInt16Ty=_llInt16Ty, llInt32Ty=_llInt32Ty, llInt64Ty=_llInt64Ty,
    llFloatTy=_llFloatTy, llDoubleTy=_llDoubleTy, llIntTy=_llIntTy, llIntPtrTy=_llIntPtrTy, llSizeTy=_llSizeTy,
    llPtrDiffTy=_llPtrDiffTy, llVoidPtrTy=_llVoidPtrTy, llInt8PtrTy=_llInt8PtrTy, llVoidPtrPtrTy=_llVoidPtrPtrTy,
    llInt8PtrPtrTy=_llInt8PtrPtrTy, llPointerWidthInBits=_llPointerWidthInBits, llPointerAlignInBytes=_llPointerAlignInBytes,
    llPointerSizeInBytes=_llPointerSizeInBytes;
@synthesize llBlockDescriptorTy=_blockDescriptorTy, llBlockLiteralType=_blockLiteralType;
@synthesize objc_msgSend=_func_objc_msgSend, objc_msgSendSuper=_func_objc_msgSendSuper,
    objc_storeWeak=_func_objc_storeWeak, objc_loadWeak=_func_objc_loadWeak, objc_allocateClassPair=_func_objc_allocateClassPair,
    objc_registerClassPair=_func_objc_registerClassPair, objc_destroyWeak=_func_objc_destroyWeak,
    class_replaceMethod=_func_class_replaceMethod, sel_registerName=_func_sel_registerName,
    objc_getClass=_func_objc_getClass, objc_retain=_func_objc_retain, objc_release=_func_objc_release,
    _Block_copy=_func__Block_copy, _Block_object_assign=_func__Block_object_assign,
    _Block_object_dispose=_func__Block_object_dispose, imp_implementationWithBlock=_func_imp_implementationWithBlock,
    object_getClass=_func_object_getClass, TQPrepareObjectForReturn=_func_TQPrepareObjectForReturn,
    objc_autorelease=_func_objc_autorelease, objc_autoreleasePoolPush=_func_objc_autoreleasePoolPush,
    objc_autoreleasePoolPop=_func_objc_autoreleasePoolPop, TQSetValueForKey=_func_TQSetValueForKey,
    TQValueForKey=_func_TQValueForKey, TQGetOrCreateClass=_func_TQGetOrCreateClass,
    TQObjectsAreEqual=_func_TQObjectsAreEqual, TQObjectsAreNotEqual=_func_TQObjectsAreNotEqual, TQObjectGetSuperClass=_func_TQObjectGetSuperClass,
    TQVaargsToArray=_func_TQVaargsToArray, TQUnboxObject=_func_TQUnboxObject,
    TQBoxValue=_func_TQBoxValue, tq_msgSend=_func_tq_msgSend, objc_retainAutoreleaseReturnValue=_func_objc_retainAutoreleaseReturnValue,
    objc_autoreleaseReturnValue=_func_objc_autoreleaseReturnValue, objc_retainAutoreleasedReturnValue=_func_objc_retainAutoreleasedReturnValue,
    objc_storeStrong=_func_objc_storeStrong;

+ (TQProgram *)programWithName:(NSString *)aName
{
    return [[[self alloc] initWithName:aName] autorelease];
}

- (id)initWithName:(NSString *)aName
{
    if(!(self = [super init])) 
        return nil;

    _name = [aName retain];
    _objcParser = [TQHeaderParser new];
    _llModule = new Module([_name UTF8String], getGlobalContext());
    llvm::LLVMContext &ctx = _llModule->getContext();

    // Cache the types
    _llVoidTy               = llvm::Type::getVoidTy(ctx);
    _llInt8Ty               = llvm::Type::getInt8Ty(ctx);
    _llInt16Ty              = llvm::Type::getInt16Ty(ctx);
    _llInt32Ty              = llvm::Type::getInt32Ty(ctx);
    _llInt64Ty              = llvm::Type::getInt64Ty(ctx);
    _llFloatTy              = llvm::Type::getFloatTy(ctx);
    _llDoubleTy             = llvm::Type::getDoubleTy(ctx);
    _llPointerWidthInBits   = 64;
    _llPointerAlignInBytes  = 8;
    _llIntTy                = TypeBuilder<int, false>::get(ctx); //llvm::IntegerType::get(ctx, 32);
    _llIntPtrTy             = llvm::IntegerType::get(ctx, _llPointerWidthInBits);
    _llInt8PtrTy            = TypeBuilder<char*, false>::get(ctx); //_llInt8Ty->getPointerTo(0);
    _llInt8PtrPtrTy         = _llInt8PtrTy->getPointerTo(0);

    // Block types
    _blockDescriptorTy = llvm::StructType::create("struct.__tq_block_descriptor",
                              _llInt64Ty, _llInt64Ty, NULL);
    Type *blockDescriptorPtrTy = llvm::PointerType::getUnqual(_blockDescriptorTy);
    _blockLiteralType = llvm::StructType::create("struct.__block_literal_generic",
                                  _llInt8PtrTy, _llIntTy, _llIntTy, _llInt8PtrTy, blockDescriptorPtrTy, NULL);

    // Cache commonly used functions
    #define DEF_EXTERNAL_FUN(name, type) \
    _func_##name = _llModule->getFunction(#name); \
    if(!_func_##name) { \
        _func_##name = Function::Create((type), GlobalValue::ExternalLinkage, #name, _llModule); \
        _func_##name->setCallingConv(CallingConv::C); \
    }

    Type *size_tTy = llvm::TypeBuilder<size_t, false>::get(ctx);

    // id(id, char*, int64)
    std::vector<Type*> args_i8Ptr_i8Ptr_sizeT;
    args_i8Ptr_i8Ptr_sizeT.push_back(_llInt8PtrTy);
    args_i8Ptr_i8Ptr_sizeT.push_back(_llInt8PtrTy);
    args_i8Ptr_i8Ptr_sizeT.push_back(size_tTy);
    FunctionType *ft_i8Ptr__i8Ptr_i8Ptr_sizeT = FunctionType::get(_llInt8PtrTy, args_i8Ptr_i8Ptr_sizeT, false);

    // void(id)
    std::vector<Type*> args_i8Ptr;
    args_i8Ptr.push_back(_llInt8PtrTy);
    FunctionType *ft_void__i8Ptr = FunctionType::get(_llVoidTy, args_i8Ptr, false);

    // void(id, int)
    std::vector<Type*> args_i8Ptr_int;
    args_i8Ptr_int.push_back(_llInt8PtrTy);
    args_i8Ptr_int.push_back(_llIntTy);
    FunctionType *ft_void__i8Ptr_int = FunctionType::get(_llVoidTy, args_i8Ptr_int, false);

    // void(id, id, int)
    std::vector<Type*> args_i8Ptr_i8Ptr_int;
    args_i8Ptr_i8Ptr_int.push_back(_llInt8PtrTy);
    args_i8Ptr_i8Ptr_int.push_back(_llInt8PtrTy);
    args_i8Ptr_i8Ptr_int.push_back(_llIntTy);
    FunctionType *ft_void__i8Ptr_i8Ptr_int = FunctionType::get(_llVoidTy, args_i8Ptr_i8Ptr_int, false);

    // BOOL(Class, char *, size_t, uint8_t, char *)
    std::vector<Type*> args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr;
    args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr.push_back(_llInt8PtrTy);
    args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr.push_back(_llInt8PtrTy);
    args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr.push_back(size_tTy);
    args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr.push_back(_llInt8Ty);
    args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr.push_back(_llInt8PtrTy);
    FunctionType *ft_i8__i8Ptr_i8Ptr_sizeT_i8_i8Ptr = FunctionType::get(_llInt8Ty, args_i8Ptr_i8Ptr_sizeT_i8_i8Ptr, false);

    // BOOL(Class, SEL, IMP, char *)
    std::vector<Type*> args_i8Ptr_i8Ptr_i8Ptr_i8Ptr;
    args_i8Ptr_i8Ptr_i8Ptr_i8Ptr.push_back(_llInt8PtrTy);
    args_i8Ptr_i8Ptr_i8Ptr_i8Ptr.push_back(_llInt8PtrTy);
    args_i8Ptr_i8Ptr_i8Ptr_i8Ptr.push_back(_llInt8PtrTy);
    args_i8Ptr_i8Ptr_i8Ptr_i8Ptr.push_back(_llInt8PtrTy);
    FunctionType *ft_i8__i8Ptr_i8Ptr_i8Ptr_i8Ptr = FunctionType::get(_llInt8Ty, args_i8Ptr_i8Ptr_i8Ptr_i8Ptr, false);

    // id(id, char*, ...)
    std::vector<Type*> args_i8Ptr_i8Ptr_variadic;
    args_i8Ptr_i8Ptr_variadic.push_back(_llInt8PtrTy);
    args_i8Ptr_i8Ptr_variadic.push_back(_llInt8PtrTy);
    FunctionType *ft_i8ptr__i8ptr_i8ptr_variadic = FunctionType::get(_llInt8PtrTy, args_i8Ptr_i8Ptr_variadic, true);

    // id(id*, id)
    std::vector<Type*> args_i8PtrPtr_i8Ptr;
    args_i8PtrPtr_i8Ptr.push_back(_llInt8PtrPtrTy);
    args_i8PtrPtr_i8Ptr.push_back(_llInt8PtrTy);
    FunctionType *ft_i8Ptr__i8PtrPtr_i8Ptr = FunctionType::get(_llInt8PtrTy, args_i8PtrPtr_i8Ptr, false);

    // id(id, id)
    std::vector<Type*> args_i8Ptr_i8Ptr;
    args_i8Ptr_i8Ptr.push_back(_llInt8PtrTy);
    args_i8Ptr_i8Ptr.push_back(_llInt8PtrTy);
    FunctionType *ft_i8Ptr__i8Ptr_i8Ptr = FunctionType::get(_llInt8PtrTy, args_i8Ptr_i8Ptr, false);

    // id(id, id, id)
    std::vector<Type*> args_i8Ptr_i8Ptr_i8ptr;
    args_i8Ptr_i8Ptr_i8ptr.push_back(_llInt8PtrTy);
    args_i8Ptr_i8Ptr_i8ptr.push_back(_llInt8PtrTy);
    args_i8Ptr_i8Ptr_i8ptr.push_back(_llInt8PtrTy);
    FunctionType *ft_i8Ptr__i8Ptr_i8Ptr_i8ptr = FunctionType::get(_llInt8PtrTy, args_i8Ptr_i8Ptr_i8ptr, false);

    // void(id*, id)
    FunctionType *ft_void__i8PtrPtr_i8Ptr = FunctionType::get(_llVoidTy, args_i8PtrPtr_i8Ptr, false);

    // void(id, id, id)
    std::vector<Type*> args_i8Ptr_i8Ptr_i8Ptr;
    args_i8Ptr_i8Ptr_i8Ptr.push_back(_llInt8PtrTy);
    args_i8Ptr_i8Ptr_i8Ptr.push_back(_llInt8PtrTy);
    args_i8Ptr_i8Ptr_i8Ptr.push_back(_llInt8PtrTy);
    FunctionType *ft_void__i8Ptr_i8Ptr_i8Ptr = FunctionType::get(_llVoidTy, args_i8Ptr_i8Ptr_i8Ptr, false);

    // void(id, id)
    FunctionType *ft_void__i8Ptr_i8Ptr = FunctionType::get(_llVoidTy, args_i8Ptr_i8Ptr, false);

    // id(id*)
    std::vector<Type*> args_i8PtrPtr;
    args_i8PtrPtr.push_back(_llInt8PtrPtrTy);
    FunctionType *ft_i8Ptr__i8PtrPtr = FunctionType::get(_llInt8PtrTy, args_i8PtrPtr, false);

    // void(id*)
    FunctionType *ft_void__i8PtrPtr = FunctionType::get(_llVoidTy, args_i8PtrPtr, false);

    // id(id)
    FunctionType *ft_i8Ptr__i8Ptr = FunctionType::get(_llInt8PtrTy, args_i8Ptr, false);

    // id()
    std::vector<Type*> args_empty;
    FunctionType *ft_i8Ptr__void = FunctionType::get(_llInt8PtrTy, args_empty, false);

    DEF_EXTERNAL_FUN(objc_allocateClassPair, ft_i8Ptr__i8Ptr_i8Ptr_sizeT);
    DEF_EXTERNAL_FUN(objc_registerClassPair, ft_void__i8Ptr);
    DEF_EXTERNAL_FUN(class_replaceMethod, ft_i8__i8Ptr_i8Ptr_i8Ptr_i8Ptr);
    DEF_EXTERNAL_FUN(imp_implementationWithBlock, ft_i8Ptr__i8Ptr);
    DEF_EXTERNAL_FUN(object_getClass, ft_i8Ptr__i8Ptr);
    DEF_EXTERNAL_FUN(objc_msgSend, ft_i8ptr__i8ptr_i8ptr_variadic);
    DEF_EXTERNAL_FUN(objc_msgSendSuper, ft_i8ptr__i8ptr_i8ptr_variadic);
    //DEF_EXTERNAL_FUN(objc_storeWeak, ft_i8Ptr__i8PtrPtr_i8Ptr);
    //DEF_EXTERNAL_FUN(objc_loadWeak, ft_i8Ptr__i8PtrPtr);
    //DEF_EXTERNAL_FUN(objc_destroyWeak, ft_void__i8PtrPtr);
    DEF_EXTERNAL_FUN(objc_retain, ft_i8Ptr__i8Ptr);
    DEF_EXTERNAL_FUN(objc_retainAutoreleaseReturnValue, ft_i8Ptr__i8Ptr);
    DEF_EXTERNAL_FUN(objc_retainAutoreleasedReturnValue, ft_i8Ptr__i8Ptr);
    DEF_EXTERNAL_FUN(objc_autoreleaseReturnValue, ft_i8Ptr__i8Ptr);
    DEF_EXTERNAL_FUN(objc_release, ft_void__i8Ptr);
    DEF_EXTERNAL_FUN(objc_autorelease, ft_i8Ptr__i8Ptr);
    DEF_EXTERNAL_FUN(sel_registerName, ft_i8Ptr__i8Ptr);
    DEF_EXTERNAL_FUN(objc_getClass, ft_i8Ptr__i8Ptr)
    DEF_EXTERNAL_FUN(_Block_copy, ft_i8Ptr__i8Ptr);
    DEF_EXTERNAL_FUN(_Block_object_assign, ft_void__i8Ptr_i8Ptr_int);
    DEF_EXTERNAL_FUN(_Block_object_dispose, ft_void__i8Ptr_int);
    DEF_EXTERNAL_FUN(TQPrepareObjectForReturn, ft_i8Ptr__i8Ptr);
    DEF_EXTERNAL_FUN(objc_autoreleasePoolPush, ft_i8Ptr__void);
    DEF_EXTERNAL_FUN(objc_autoreleasePoolPop, ft_void__i8Ptr);
    DEF_EXTERNAL_FUN(objc_storeStrong, ft_i8Ptr__i8PtrPtr_i8Ptr);
    DEF_EXTERNAL_FUN(TQSetValueForKey, ft_void__i8Ptr_i8Ptr_i8Ptr);
    DEF_EXTERNAL_FUN(TQValueForKey, ft_i8Ptr__i8Ptr_i8Ptr);
    DEF_EXTERNAL_FUN(TQGetOrCreateClass, ft_i8Ptr__i8Ptr_i8Ptr);
    DEF_EXTERNAL_FUN(TQObjectsAreEqual, ft_i8Ptr__i8Ptr_i8Ptr);
    DEF_EXTERNAL_FUN(TQObjectsAreNotEqual, ft_i8Ptr__i8Ptr_i8Ptr);
    DEF_EXTERNAL_FUN(TQObjectGetSuperClass, ft_i8Ptr__i8Ptr);
    DEF_EXTERNAL_FUN(TQVaargsToArray, ft_i8Ptr__i8Ptr);
    DEF_EXTERNAL_FUN(TQUnboxObject, ft_void__i8Ptr_i8Ptr_i8Ptr)
    DEF_EXTERNAL_FUN(TQBoxValue, ft_i8Ptr__i8Ptr_i8Ptr)
    DEF_EXTERNAL_FUN(tq_msgSend, ft_i8ptr__i8ptr_i8ptr_variadic)

#undef DEF_EXTERNAL_FUN

    TQInitializeRuntime();
    InitializeNativeTarget();

    _searchPaths = [[NSMutableArray alloc] initWithObjects:@".",
                        @"~/Library/Frameworks", @"/Library/Frameworks",
                        @"/System/Library/Frameworks/", nil];
    _allowedFileExtensions = [[NSMutableArray alloc] initWithObjects:@"tq", @"h", nil];

    return self;
}

- (void)dealloc
{
    [_searchPaths release];
    [_allowedFileExtensions release];
    delete _llModule;
    [_objcParser release];
    [super dealloc];
}


#pragma mark - Execution

// Prepares & optimizes the program tree before execution
- (void)_preprocessNode:(TQNode *)aNodeToIterate withTrace:(NSMutableArray *)aTrace
{
    if(!aNodeToIterate)
        return;
    [aTrace addObject:aNodeToIterate];
    [aNodeToIterate iterateChildNodes:^(TQNode *node) {
        for(Class processor in [TQProcessor allProcessors]) {
            [processor processNode:node withTrace:aTrace];
        }
        [self _preprocessNode:node withTrace:aTrace];
   }];
   [aTrace removeLastObject];
}

// Executes the current program tree
- (id)_executeRoot:(TQNodeRootBlock *)aNode
{
    NSError *err = nil;
    [aNode generateCodeInProgram:self block:nil root:aNode error:&err];
    if(err) {
        TQLog(@"Error: %@", err);
        return NO;
    }

    if(_shouldShowDebugInfo) {
        llvm::EnableStatistics();
        _llModule->dump();
        // Verify that the program is valid
        verifyModule(*_llModule, PrintMessageAction);
    }

    // Compile program
    TargetOptions Opts;
    Opts.JITEmitDebugInfo = true;
    Opts.GuaranteedTailCallOpt = true;

    PassRegistry &Registry = *PassRegistry::getPassRegistry();
    initializeCore(Registry);
    initializeScalarOpts(Registry);
    initializeVectorization(Registry);
    initializeIPO(Registry);
    initializeAnalysis(Registry);
    initializeIPA(Registry);
    initializeTransformUtils(Registry);
    initializeInstCombine(Registry);
    initializeInstrumentation(Registry);
    initializeTarget(Registry);

    PassManager modulePasses;

    EngineBuilder factory(_llModule);
    factory.setEngineKind(llvm::EngineKind::JIT);
    factory.setTargetOptions(Opts);
    factory.setOptLevel(CodeGenOpt::Aggressive);
    ExecutionEngine *engine = factory.create();

    //engine->DisableLazyCompilation();

    // Optimization pass
    FunctionPassManager fpm = FunctionPassManager(_llModule);

    fpm.add(new TargetData(*engine->getTargetData()));
    PassManagerBuilder builder = PassManagerBuilder();
    builder.OptLevel = 3;
    PassManagerBuilder Builder;
    builder.Inliner = createFunctionInliningPass(275);
    builder.populateFunctionPassManager(fpm);
    builder.populateModulePassManager(modulePasses);

    fpm.add(createInstructionCombiningPass());
    // Eliminate unnecessary alloca.
    fpm.add(createPromoteMemoryToRegisterPass());
    // Reassociate expressions.
    fpm.add(createReassociatePass());
    // Eliminate Common SubExpressions.
    fpm.add(createGVNPass());
    // Simplify the control flow graph (deleting unreachable blocks, etc).
    fpm.add(createCFGSimplificationPass());
    // Eliminate tail calls.
    fpm.add(createTailCallEliminationPass());


    if(!_shouldShowDebugInfo) {
        fpm.run(*aNode.function);
        modulePasses.run(*_llModule);
    }

    if(_shouldShowDebugInfo) {
        //_llModule->dump();
        llvm::PrintStatistics();
        fprintf(stderr, "---------------------\n");
    }

    id(*rootPtr)() = (id(*)())engine->getPointerToFunction(aNode.function);

    uint64_t startTime = mach_absolute_time();
    // Execute code
    id ret = rootPtr();

    uint64_t ns = mach_absolute_time() - startTime;
    struct mach_timebase_info timebase;
    mach_timebase_info(&timebase);
    double sec = ns * timebase.numer / timebase.denom / 1000000000.0;

    if(_shouldShowDebugInfo) {
        fprintf(stderr, "---------------------\n");
        TQLog(@"Run time: %f sec. Ret: %p", sec, ret);
        TQLog(@"'root' retval:  %p: %@ (%@)", ret, ret ? ret : nil, [ret class]);
    }

    return ret;
}

- (TQNodeRootBlock *)_rootFromFile:(NSString *)aPath error:(NSError **)aoErr
{
    NSString *script = [NSString stringWithContentsOfFile:aPath usedEncoding:NULL error:nil];
    if(!script)
        TQAssert(NO, @"Unable to load script from %@", aPath);
    return [self _parseScript:script error:aoErr];
}
- (id)executeScriptAtPath:(NSString *)aPath error:(NSError **)aoErr
{
    return [self _executeRoot:[self _rootFromFile:aPath error:aoErr]];
}

- (TQNodeRootBlock *)_parseScript:(NSString *)aScript error:(NSError **)aoErr
{
    GREG greg;
    yyinit(&greg);

    TQParserState parserState = {0};
    parserState.currentLine = 1;
    parserState.stack = [NSMutableArray array];
    parserState.script = [aScript UTF8String];
    parserState.length = [aScript length];
    greg.data = &parserState;

    [parserState.stack addObject:[NSMutableArray array]];

    @try {
        while(yyparse(&greg));
    } @catch(NSException *e) {
        TQLog(@"%@", [e reason]);
        return nil;
    } @finally {
        yydeinit(&greg);
    }

    if(!parserState.root)
        return nil;

    [self _preprocessNode:parserState.root withTrace:[NSMutableArray array]];
    if(_shouldShowDebugInfo)
        TQLog(@"%@", parserState.root);
    return parserState.root;
}
- (id)executeScript:(NSString *)aScript error:(NSError **)aoErr
{
    return [self _executeRoot:[self _parseScript:aScript error:aoErr]];
}


#pragma mark - Utilities

- (NSString *)_resolveImportPath:(NSString *)aPath
{
#define NOT_FOUND() do { TQLog(@"No file found for path '%@'", aPath); return nil; } while(0)
    BOOL isDir;
    NSFileManager *fm = [NSFileManager defaultManager];
    if([aPath hasPrefix:@"/"]) {
        NSLog(@"Returning %@", aPath);
        if([fm fileExistsAtPath:aPath isDirectory:&isDir] && !isDir)
            return aPath;
        NOT_FOUND();
    }
    NSArray *testPathComponents = [aPath pathComponents];
    if(![testPathComponents count])
        NOT_FOUND();

    BOOL hasExtension = [[aPath pathExtension] length] > 0;
    BOOL usesSubdir   = [testPathComponents count] > 1;

    for(NSString *searchPath in _searchPaths) {
        if(![fm fileExistsAtPath:searchPath isDirectory:&isDir] || !isDir)
            continue;

        for(NSString *candidate in [fm contentsOfDirectoryAtPath:searchPath error:nil]) {
            if([[candidate pathExtension] isEqualToString:@"framework"]) {
                NSString *frameworkDirName = usesSubdir ? [testPathComponents objectAtIndex:0] : [[aPath lastPathComponent] stringByDeletingPathExtension];
                if(![[[candidate lastPathComponent] stringByDeletingPathExtension] isEqualToString:frameworkDirName])
                    continue;
                if(usesSubdir)
                    aPath = [[testPathComponents subarrayWithRange:(NSRange){ 1, [testPathComponents count] - 1 }] componentsJoinedByString:@"/"];
                searchPath = [[searchPath stringByAppendingPathComponent:candidate] stringByAppendingPathComponent:@"Headers"];
                break;
            }
        }
        NSString *finalPath = [searchPath stringByAppendingPathComponent:aPath];
        if(hasExtension) {
            if([fm fileExistsAtPath:finalPath isDirectory:&isDir] && !isDir)
                return finalPath;
        } else {
            for(NSString *ext in _allowedFileExtensions) {
                NSString *currPath = [finalPath stringByAppendingPathExtension:ext];
                if([fm fileExistsAtPath:currPath isDirectory:&isDir] && !isDir)
                    return currPath;
            }
        }
    }

    NOT_FOUND();
#undef NOT_FOUND
}

- (llvm::Value *)getGlobalStringPtr:(NSString *)aStr withBuilder:(llvm::IRBuilder<> *)aBuilder
{
    NSString *globalName = [NSString stringWithFormat:@"TQConstCStr_%@", aStr];
    GlobalVariable *global = _llModule->getGlobalVariable([globalName UTF8String], true);
    if(!global) {
        Constant *strConst = ConstantDataArray::getString(_llModule->getContext(), [aStr UTF8String]);
        global = new GlobalVariable(*_llModule, strConst->getType(),
                                    true, GlobalValue::PrivateLinkage,
                                    strConst, [globalName UTF8String]);
    }

    Value *zero = ConstantInt::get(Type::getInt32Ty(_llModule->getContext()), 0);
    Value *indices[] = { zero, zero };
    return aBuilder->CreateInBoundsGEP(global, indices);
}

- (llvm::Value *)getGlobalStringPtr:(NSString *)aStr inBlock:(TQNodeBlock *)aBlock
{
    return [self getGlobalStringPtr:aStr withBuilder:aBlock.builder];
}

- (void)insertLogUsingBuilder:(llvm::IRBuilder<> *)aBuilder withStr:(NSString *)txt
{
    std::vector<Type*> nslog_args;
    nslog_args.push_back(_llInt8PtrTy);
    FunctionType *printf_type = FunctionType::get(_llIntTy, nslog_args, true);
    Function *func_printf = _llModule->getFunction("printf");
    if(!func_printf) {
        func_printf = Function::Create(printf_type, GlobalValue::ExternalLinkage, "printf", _llModule);
        func_printf->setCallingConv(CallingConv::C);
    }
    std::vector<Value*> args;
    args.push_back([self getGlobalStringPtr:@"> %s\n" withBuilder:aBuilder]);
    args.push_back([self getGlobalStringPtr:txt withBuilder:aBuilder]);
    aBuilder->CreateCall(func_printf, args);
}

- (llvm::Type *)llvmTypeFromEncoding:(const char *)aEncoding
{
    switch(*aEncoding) {
        case _C_ID:
        case _C_CLASS:
        case _C_SEL:
        case _C_PTR:
        case _C_CHARPTR:
        case _TQ_C_LAMBDA_B:
            return _llInt8PtrTy;
        case _C_DBL:
            return _llDoubleTy;
        case _C_FLT:
            return _llFloatTy;
        case _C_INT:
            return _llIntTy;
        case _C_SHT:
            return _llInt16Ty;
        case _C_CHR:
            return _llInt8Ty;
        case _C_BOOL:
            return _llInt8Ty;
        case _C_LNG:
            return _llInt64Ty;
        case _C_LNG_LNG:
            return _llInt64Ty;
        case _C_UINT:
            return _llIntTy;
        case _C_USHT:
            return _llInt16Ty;
        case _C_ULNG:
            return _llInt64Ty;
        case _C_ULNG_LNG:
            return _llInt64Ty;
        case _C_VOID:
            return _llVoidTy;
        case _C_STRUCT_B: {
            const char *field = strstr(aEncoding, "=") + 1;
            assert((uintptr_t)field > 1);
            std::vector<Type*> fields;
            while(*field != _C_STRUCT_E) {
                fields.push_back([self llvmTypeFromEncoding:field]);
                field = TQGetSizeAndAlignment(field, NULL, NULL);
            }
            return StructType::get(_llModule->getContext(), fields);
        }
        case _C_UNION_B:
            TQLog(@"unions -> llvm not yet supported");
            exit(1);
        break;
        default:
            [NSException raise:NSGenericException
                        format:@"Unsupported type %c!", *aEncoding];
            return NULL;
    }
}
@end
