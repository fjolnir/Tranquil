#import "TQNodeMessage.h"
#import "../TQProgram.h"
#import "TQNodeArgument.h"
#import "TQNodeVariable.h"

using namespace llvm;

@implementation TQNodeMessage
@synthesize receiver=_receiver, arguments=_arguments;

+ (TQNodeMessage *)nodeWithReceiver:(TQNode *)aNode
{
    return [[[self alloc] initWithReceiver:aNode] autorelease];
}

- (id)initWithReceiver:(TQNode *)aNode
{
    if(!(self = [super init]))
        return nil;

    _receiver = [aNode retain];
    _arguments = [[NSMutableArray alloc] init];

    return self;
}

- (void)dealloc
{
    [_receiver release];
    [_arguments release];
    [super dealloc];
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    TQNode *ref = nil;
    if([aNode isEqual:self])
        return self;
    else if((ref = [_receiver referencesNode:aNode]))
        return ref;
    else if((ref = [_arguments tq_referencesNode:aNode]))
        return ref;
    return nil;
}

- (NSString *)description
{
    NSMutableString *out = [NSMutableString stringWithString:@"<msg@ "];
    [out appendFormat:@"%@ ", _receiver];

    for(TQNodeArgument *arg in _arguments) {
        [out appendFormat:@"%@ ", arg];
    }

    [out appendString:@".>"];
    return out;
}

- (NSString *)selector
{
    NSMutableString *selStr = [NSMutableString string];
    if(_arguments.count == 1 && ![[_arguments objectAtIndex:0] passedNode])
        [selStr appendString:[[_arguments objectAtIndex:0] selectorPart]];
    else {
        for(TQNodeArgument *arg in _arguments) {
            [selStr appendFormat:@"%@:", arg.selectorPart ? arg.selectorPart : @""];
        }
    }
    return selStr;
}


- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock
                         withArguments:(std::vector<llvm::Value*>)aArgs error:(NSError **)aoErr
{
    NSString *selStr = [self selector];
    BOOL needsAutorelease = NO;
    if([selStr hasPrefix:@"alloc"])
        needsAutorelease = YES;
    else if([selStr hasSuffix:@"copy"])
        needsAutorelease = YES;
    else if([selStr isEqualToString:@"new"])
        needsAutorelease = YES;

    // Cache the selector into a global
    Module *mod = aProgram.llModule;
    Value *selectorGlobal = mod->getGlobalVariable([selStr UTF8String], false);
    if(!selectorGlobal) {
        Function *rootFunction = aProgram.root.function;
        IRBuilder<> rootBuilder(&rootFunction->getEntryBlock(), rootFunction->getEntryBlock().begin());
        Value *selector = [aProgram getGlobalStringPtr:selStr inBlock:aBlock];

        CallInst *selReg = rootBuilder.CreateCall(aProgram.sel_registerName, selector);
        selectorGlobal =  new GlobalVariable(*mod, aProgram.llInt8PtrTy, false, GlobalVariable::InternalLinkage,
                                             ConstantPointerNull::get(aProgram.llInt8PtrTy), [selStr UTF8String]);
        rootBuilder.CreateStore(selReg, selectorGlobal);
    }
    selectorGlobal = aBlock.builder->CreateLoad(selectorGlobal);


    aArgs.insert(aArgs.begin(), selectorGlobal);
    aArgs.insert(aArgs.begin(), [_receiver generateCodeInProgram:aProgram block:aBlock error:aoErr]);


    Value *ret;
    if([_receiver isMemberOfClass:[TQNodeSuper class]])
        ret = aBlock.builder->CreateCall(aProgram.objc_msgSendSuper, aArgs);
    else {
        ret = aBlock.builder->CreateCall(aProgram.tq_msgSend, aArgs);
        if(needsAutorelease)
            ret = aBlock.builder->CreateCall(aProgram.objc_autoreleaseReturnValue, ret);
    }
    return ret;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
    Module *mod = aProgram.llModule;
    std::vector<Value*> args;
    for(TQNodeArgument *arg in _arguments) {
        if(!arg.passedNode)
            break;
        args.push_back([arg generateCodeInProgram:aProgram block:aBlock error:aoErr]);
    }
    // From what I can tell having read the ABI spec for x86-64, it is safe to pass this added argument. TODO: verify this holds for ARM&x86
    // Sentinel argument to make variadic methods possible (without resorting to special cases in tq_msgsend, and using libffi; which would kill performance)
    args.push_back(aBlock.builder->CreateLoad(mod->getOrInsertGlobal("TQSentinel", aProgram.llInt8PtrTy), "sentinel"));

    return [self generateCodeInProgram:aProgram block:aBlock withArguments:args error:aoErr];
}

@end
