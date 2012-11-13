#import "TQProgram.h"
#import "TQProgram+Internal.h"
#import "TQParse.h"
#import "TQNode.h"
#import "TQNodeVariable.h"
#import "TQNodeCustom.h"
#import "Processors/TQProcessor.h"
#import "ObjcSupport/TQHeaderParser.h"
#import "../Runtime/TQRuntime.h"
#import "../Runtime/TQBoxedObject.h"
#import "../Runtime/OFString+TQAdditions.h"
#import "../Shared/TQDebug.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <llvm/Transforms/IPO/PassManagerBuilder.h>
#import <llvm/Target/TargetData.h>
#import <mach/mach_time.h>

#ifdef TQ_PROFILE
#import <google/profiler.h>
#endif

//#import "parse.mm" // Includes the parser source

#include <llvm/Module.h>
#include <llvm/DerivedTypes.h>
#include <llvm/Constants.h>
#include <llvm/CallingConv.h>
#include <llvm/Instructions.h>
#include <llvm/PassManager.h>
#include <llvm/Analysis/Verifier.h>
#include <llvm/Target/TargetData.h>
#include <llvm/Target/TargetData.h>
#include <llvm/Target/TargetMachine.h>
#include <llvm/Target/TargetOptions.h>
#include <llvm/Transforms/Scalar.h>
#include <llvm/Transforms/IPO.h>
#include <llvm/Support/raw_ostream.h>
#if !defined(LLVM_TOT)
# include <llvm/Support/system_error.h>
#endif
#include <llvm/Support/PrettyStackTrace.h>
#include <llvm/Support/MemoryBuffer.h>
#include <llvm/Intrinsics.h>
#include <llvm/Bitcode/ReaderWriter.h>
#include <llvm/LLVMContext.h>
#include <llvm/Support/ToolOutputFile.h>
#include <llvm/Support/TargetRegistry.h>
#include <llvm/Support/Host.h>
#include "llvm/ADT/Statistic.h"

using namespace llvm;

OFString * const kTQSyntaxErrorException = @"TQSyntaxErrorException";

static TQProgram *sharedInstance;

@implementation TQProgram
@synthesize name=_name, llModule=_llModule, cliArgGlobal=_cliArgGlobal, shouldShowDebugInfo=_shouldShowDebugInfo,
            objcParser=_objcParser, searchPaths=_searchPaths, allowedFileExtensions=_allowedFileExtensions,
            useAOTCompilation=_useAOTCompilation, outputPath=_outputPath, arguments=_arguments, globals=_globals,
            evaluatedPaths=_evaluatedPaths;
@synthesize globalQueue=_globalQueue, debugBuilder=_debugBuilder;

+ (void)initialize
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] initWithName:@"Global"];
    });
}

+ (TQProgram *)sharedProgram
{
    return sharedInstance;
}

+ (TQProgram *)programWithName:(OFString *)aName
{
    return [[[self alloc] initWithName:aName] autorelease];
}

- (id)initWithName:(OFString *)aName
{
    if(!(self = [super init]))
        return nil;

    _name = [aName retain];
    _objcParser = [TQHeaderParser new];
    _llModule = new Module([_name UTF8String], getGlobalContext());
    llvm::LLVMContext &ctx = _llModule->getContext();

    _debugBuilder = new DIBuilder(*_llModule);

    TQInitializeRuntime();
    InitializeNativeTarget();
    LLVMInitializeX86Target();
    
    _globals     = [OFMutableDictionary new];
    _searchPaths = [[OFMutableArray alloc] initWithObjects:@".",
                        @"~/Library/Frameworks", @"/Library/Frameworks",
                        @"/System/Library/Frameworks/", @"/usr/include/", @"/usr/local/include/",
                        @"/usr/local/tranquil/llvm/include", nil];
    _allowedFileExtensions = [[OFMutableArray alloc] initWithObjects:@"tq", @"h", nil];

    return self;
}

- (void)dealloc
{
    [_searchPaths release];
    [_globals release];
    [_allowedFileExtensions release];
    [_objcParser release];
    delete _llModule;
    [_arguments release];
    [super dealloc];
}

#pragma mark - Execution

// Prepares & optimizes the program tree before execution
- (void)_preprocessNode:(TQNode *)aNodeToIterate withTrace:(OFMutableArray *)aTrace
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

- (id)_executeRoot:(TQNodeRootBlock *)aNode error:(TQError **)aoErr
{
    if(!aNode)
        return nil;

    BOOL shouldResetEvalPaths = !_evaluatedPaths;
    if(shouldResetEvalPaths)
        _evaluatedPaths = [OFMutableArray array];

    GlobalVariable *argGlobal = NULL;
    if(!_useAOTCompilation) {
        TQNodeVariable *varArgVar = [TQNodeVariable nodeWithName:@"..."];
        if([aNode referencesNode:varArgVar]) {
            // Create a global for the argument array
            Type *byRefType = [TQNodeVariable captureStructTypeInProgram:self];
            argGlobal = new GlobalVariable(*_llModule, byRefType, false, GlobalVariable::InternalLinkage,
                                           ConstantAggregateZero::get(byRefType), "TQGlobalVar_...");
            _argGlobalForJIT.isa        = nil;
            _argGlobalForJIT.flags      = 0;
            _argGlobalForJIT.size       = sizeof(TQBlockByRef);
            _argGlobalForJIT.value      = nil;
            _argGlobalForJIT.value      = _arguments;
            _argGlobalForJIT.forwarding = &_argGlobalForJIT;
            // Insert a reference to the '...' variable so that child blocks know to capture it
            [aNode.statements insertObject:varArgVar atIndex:0];
        }

        // Global for the dispatch queue
        _globalQueue = _llModule->getNamedGlobal("TQGlobalQueue");
        if(!_globalQueue)
            _globalQueue = new GlobalVariable(*_llModule, self.llInt8PtrTy, false, GlobalVariable::ExternalLinkage,
                                              NULL, "TQGlobalQueue");
    } else {
        _globalQueue = _llModule->getNamedGlobal("TQGlobalQueue");
        if(!_globalQueue)
            _globalQueue = new GlobalVariable(*_llModule, self.llInt8PtrTy, false, GlobalVariable::InternalLinkage,
                                              ConstantPointerNull::get(self.llInt8PtrTy), "TQGlobalQueue");
    }

    TQError *err = nil;
    [aNode generateCodeInProgram:self block:nil root:aNode error:&err];
    if(err) {
        TQLog(@"Error: %@", err);
        if(shouldResetEvalPaths)
            _evaluatedPaths = nil;
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
    Opts.JITExceptionHandling = true;
    Opts.JITEmitDebugInfoToDisk = true;
    Opts.GuaranteedTailCallOpt = true;
    Opts.NoFramePointerElim = true;

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

    FunctionPassManager fpm = FunctionPassManager(_llModule);

    if(!_useAOTCompilation) {
        if(!_executionEngine) {
            EngineBuilder factory(_llModule);
            factory.setEngineKind(llvm::EngineKind::JIT);
            factory.setTargetOptions(Opts);
            factory.setOptLevel(CodeGenOpt::Aggressive);
            factory.setUseMCJIT(true);
            factory.setRelocationModel(Reloc::PIC_);
            _executionEngine = factory.create();
            //_executionEngine->DisableLazyCompilation();
            fpm.add(new TargetData(*_executionEngine->getTargetData()));
        }
        if(argGlobal)
            _executionEngine->addGlobalMapping(argGlobal, (void*)&_argGlobalForJIT);
        if(!_globalQueueForJIT)
            _globalQueueForJIT = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _executionEngine->addGlobalMapping(_globalQueue, (void*)&_globalQueueForJIT);
    }

    // Optimization pass
    PassManagerBuilder builder = PassManagerBuilder();
    builder.OptLevel = 3;
    PassManagerBuilder Builder;
    builder.Inliner = createFunctionInliningPass();
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

   if(_useAOTCompilation) {
        // Generate a main function
        std::vector<Type *> paramTypes;
        paramTypes.push_back(self.llIntTy);
        paramTypes.push_back(self.llInt8PtrPtrTy);

        TQNodeRootBlock *mainBlk = [TQNodeRootBlock node];
        mainBlk.invokeName = @"main";
        mainBlk.retType    = @"i";
        mainBlk.argTypes   = [OFMutableArray arrayWithObjects:@"i", @"^*", nil];

        TQNodeVariable *cliArgVar = [TQNodeVariable nodeWithName:@"..."];
        [_globals setObject:cliArgVar forKey:@"..."];
        [mainBlk.statements addObject:[TQNodeCustom nodeWithBlock:^(TQProgram *aProgram, TQNodeBlock *aBlock, TQNodeRootBlock *aRoot) {
            aBlock.builder->CreateCall(self.TQInitializeRuntime);
            llvm::Function::arg_iterator argumentIterator = aBlock.function->arg_begin();

            // Create the app wide dispatch queue
            Value *queue = aBlock.builder->CreateCall2(self.dispatch_get_global_queue, ConstantInt::get(self.llLongTy, DISPATCH_QUEUE_PRIORITY_DEFAULT), ConstantInt::get(self.llLongTy, 0));
            aBlock.builder->CreateStore(queue, _globalQueue);

            [cliArgVar store:aBlock.builder->CreateCall2(self.TQCliArgsToArray, argumentIterator, ++argumentIterator)
                   inProgram:aProgram
                       block:mainBlk
                        root:(TQNodeRootBlock *)mainBlk
                       error:nil];

            aBlock.builder->CreateCall(aNode.function);
            aBlock.builder->CreateCall(self.objc_autoreleasePoolPop, aBlock.autoreleasePool);
            aBlock.builder->CreateRet(ConstantInt::get(self.llIntTy, 0));

            return (Value *)NULL;
        }]];

        [mainBlk generateCodeInProgram:self block:nil root:mainBlk error:&err];

        // Output
        Opts.JITEmitDebugInfo = false;
        std::string err;
        std::string targetTriple, featureStr, cpuName;
        switch(_targetArch) {
            case kTQArchitectureHost:
                targetTriple = sys::getDefaultTargetTriple();
                featureStr   = "";
                cpuName      = sys::getHostCPUName();
                break;
            case kTQArchitectureI386:
                targetTriple = "i386-apple-darwin11.0.0"; // TODO make dynamic
                featureStr   = "";
                cpuName      = "corei7-avx";
                break;
            case kTQArchitectureX86_64:
                targetTriple = "x86_64-apple-darwin11.0.0"; // TODO make dynamic
                featureStr   = "";
                cpuName      = "corei7-avx";
                break;
            case kTQArchitectureARMv7:
                targetTriple = "armv7-apple-darwin11.0.0"; // TODO make dynamic
                featureStr   = "";
                cpuName      = "";
        }
        printf("%s\n", cpuName.c_str());
        const Target *target = TargetRegistry::lookupTarget(targetTriple, err);
        TQAssert(err.empty(), @"Unable to get target data");

        TargetMachine *machine = target->createTargetMachine(targetTriple, cpuName, featureStr, Opts);
        TQAssert(machine, @"Unable to create llvm target machine");
        modulePasses.add(new TargetData(*(machine->getTargetData())));
        modulePasses.run(*_llModule);
        fpm.run(*aNode.function);

        //llvm::PrintStatistics();
        verifyModule(*_llModule, PrintMessageAction);
        _llModule->dump();

        raw_fd_ostream out([_outputPath UTF8String], err, raw_fd_ostream::F_Binary);
        TQAssert(err.empty(), @"Error opening output file for bitcode: %@", _outputPath);
        WriteBitcodeToFile(_llModule, out);
        out.close();
        exit(0);
    }

    if(!_shouldShowDebugInfo) {
        fpm.run(*aNode.function);
        modulePasses.run(*_llModule);
    }

    if(_shouldShowDebugInfo) {
        //_llModule->dump();
        llvm::PrintStatistics();
        fprintf(stderr, "---------------------\n");
    }

    id(*rootPtr)() = (id(*)())_executionEngine->getPointerToFunction(aNode.function);

    uint64_t startTime = mach_absolute_time();
    // Execute code
#ifdef TQ_PROFILE
    ProfilerStart("tqprof.txt");
#endif
    id ret = nil;
    @try {
        ret = rootPtr();
    } @catch (TQAssertException *e) {
        if(aoErr) *aoErr = [TQError withDomain:kTQRuntimeErrorDomain
                                          code:kTQObjCException
                                          info:[e reason]];
    }
#ifdef TQ_PROFILE
    ProfilerStop();
#endif

    if(shouldResetEvalPaths)
        _evaluatedPaths = nil;

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

- (TQNodeRootBlock *)_rootFromFile:(OFString *)aPath error:(TQError **)aoErr
{
    OFString *script = [OFString stringWithContentsOfFile:aPath];
    if(!script)
        TQAssert(NO, @"Unable to load script from %@", aPath);
    return [self _parseScript:script error:aoErr];
}
- (id)executeScriptAtPath:(OFString *)aPath error:(TQError **)aoErr
{
    TQNodeRootBlock *root = [self _rootFromFile:aPath error:aoErr];
    if(!root)
        return nil;
    return [self _executeRoot:root error:aoErr];
}

- (TQNodeRootBlock *)_parseScript:(OFString *)aScript error:(TQError **)aoErr
{
    // Remove shebang
    if([aScript hasPrefix:@"#!"]) {
        // TODO Make this handle multibytes
        int lineEnd = 0;
        const char *cStr = [aScript UTF8String];
        for(lineEnd = 0; lineEnd < [aScript length] && cStr[lineEnd] != '\n'; ++lineEnd);
        aScript = [aScript substringFromIndex:lineEnd];
    }

    TQNodeRootBlock *root = TQParseString(aScript, aoErr);
    if(!root)
        return nil;

    // Initialize the debug unit on the root
    const char *filename = "<none>";
    const char *dir      = "<none>";
    _debugBuilder->createCompileUnit(dwarf::DW_LANG_ObjC, filename, dir, TRANQUIL_DEBUG_DESCR, true, "", 1); // Use DW_LANG_Tranquil ?
    root.debugUnit = DICompileUnit(_debugBuilder->getCU());

    [self _preprocessNode:root withTrace:[OFMutableArray array]];
    if(_shouldShowDebugInfo)
        TQLog(@"%@", root);
    return root;
}

- (id)executeScript:(OFString *)aScript error:(TQError **)aoErr
{
    TQNodeRootBlock *root = [self _parseScript:aScript error:aoErr];
    if(!root)
        return nil;
    return [self _executeRoot:root error:aoErr];
}


#pragma mark - Utilities

- (OFString *)_resolveImportPath:(OFString *)aPath
{
#define NOT_FOUND() do { TQLog(@"No file found for path '%@'", aPath); return nil; } while(0)
    BOOL isDir;
    if([aPath hasPrefix:@"/"]) {
        if([OFFile fileExistsAtPath:aPath])
            return aPath;
        NOT_FOUND();
    }
    OFArray *testPathComponents = [aPath pathComponents];
    if(![testPathComponents count]) {
        NOT_FOUND();
    }

    BOOL hasExtension = [[aPath pathExtension] length] > 0;
    BOOL usesSubdir   = [testPathComponents count] > 1;

    for(OFString *searchPath in _searchPaths) {
        if(![OFFile directoryExistsAtPath:searchPath])
            continue;

        for(OFString *candidate in [OFFile filesInDirectoryAtPath:searchPath]) {
            if([[candidate pathExtension] isEqual:@"framework"]) {
                OFString *frameworkDirName = usesSubdir ? [testPathComponents objectAtIndex:0] : [[aPath lastPathComponent] stringByDeletingPathExtension];
                if(![[[candidate lastPathComponent] stringByDeletingPathExtension] isEqual:frameworkDirName])
                    continue;
                if(usesSubdir)
                    aPath = [[testPathComponents objectsInRange:(of_range_t){ 1, [testPathComponents count] - 1 }] componentsJoinedByString:@"/"];
                searchPath = [[searchPath stringByAppendingPathComponent:candidate] stringByAppendingPathComponent:@"Headers"];
                break;
            }
        }
        OFString *finalPath = [searchPath stringByAppendingPathComponent:aPath];
        if(hasExtension) {
            if([OFFile fileExistsAtPath:finalPath])
                return finalPath;
        } else {
            for(OFString *ext in _allowedFileExtensions) {
                OFString *currPath = [finalPath stringByAppendingPathExtension:ext];
                if([OFFile fileExistsAtPath:currPath])
                    return currPath;
            }
        }
    }

    NOT_FOUND();
#undef NOT_FOUND
}

- (llvm::Value *)getGlobalStringPtr:(OFString *)aStr withBuilder:(llvm::IRBuilder<> *)aBuilder
{
    OFString *globalName;
    // When compiling AOT certain symbols in the global name can cause llvm to generate invalid ASM => we use the hash in that case (which destroys the output's readbility)
    if(_useAOTCompilation)
        globalName = [OFString stringWithFormat:@"TQConstCStr_%ld", [aStr hash]];
    else
        globalName = [OFString stringWithFormat:@"TQConstCStr_%@", aStr];

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

- (llvm::Value *)getGlobalStringPtr:(OFString *)aStr inBlock:(TQNodeBlock *)aBlock
{
    return [self getGlobalStringPtr:aStr withBuilder:aBlock.builder];
}

- (void)insertLogUsingBuilder:(llvm::IRBuilder<> *)aBuilder withStr:(OFString *)txt
{
    std::vector<Type*> nslog_args;
    nslog_args.push_back(self.llInt8PtrTy);
    FunctionType *printf_type = FunctionType::get(self.llIntTy, nslog_args, true);
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

@end
