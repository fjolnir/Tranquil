#import "TQNodeCall.h"
#import "../TQProgram.h"
#import "TQNodeBlock.h"
#import "TQNodeArgument.h"
#import "TQNodeVariable.h"

using namespace llvm;

@implementation TQNodeCall
@synthesize callee=_callee, arguments=_arguments;

+ (TQNodeCall *)nodeWithCallee:(TQNode *)aCallee
{
return [[[self alloc] initWithCallee:aCallee] autorelease];
}

- (id)initWithCallee:(TQNode *)aCallee
{
    if(!(self = [super init]))
        return nil;

    _callee = [aCallee retain];
    _arguments = [[NSMutableArray alloc] init];

    return self;
}

- (void)dealloc
{
    [_callee release];
    [_arguments release];
    [super dealloc];
}

- (NSString *)description
{
    NSMutableString *out = [NSMutableString stringWithString:@"<call@ "];
    if(_callee)
        [out appendFormat:@"%@(", _callee];

    for(TQNodeArgument *arg in _arguments) {
        [out appendFormat:@"%@, ", arg];
    }

    [out appendString:@")>"];
    return out;
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    TQNode *ref = nil;

    if([self isEqual:aNode])
        return self;
    else if((ref = [_callee referencesNode:aNode]))
        return ref;
    if((ref = [_arguments tq_referencesNode:aNode]))
        return ref;

    return nil;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock
                         withArguments:(std::vector<llvm::Value*>)aArgs error:(NSError **)aoErr
{
    IRBuilder<> *builder = aBlock.builder;

    Value *callee = [_callee generateCodeInProgram:aProgram block:aBlock error:aoErr];
    aArgs.insert(aArgs.begin(), callee);

    // Load&Call the dispatcher
    NSString *dispatcherName = [NSString stringWithFormat:@"TQDispatchBlock%ld", aArgs.size() - 1];
    Function *dispatcher = aProgram.llModule->getFunction([dispatcherName UTF8String]);
    if(!dispatcher) {
        std::vector<Type*> argtypes(aArgs.size(), aProgram.llInt8PtrTy);
        FunctionType *funType = FunctionType::get(aProgram.llInt8PtrTy, argtypes, false);
        dispatcher = Function::Create(funType, GlobalValue::ExternalLinkage, [dispatcherName UTF8String], aProgram.llModule);
        dispatcher->setCallingConv(CallingConv::C);
    }

    return builder->CreateCall(dispatcher, aArgs);
}


- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
    IRBuilder<> *builder = aBlock.builder;

    std::vector<Value*> args;
    for(TQNodeArgument *arg in _arguments) {
        args.push_back([arg generateCodeInProgram:aProgram block:aBlock error:aoErr]);
    }
    return [self generateCodeInProgram:aProgram block:aBlock withArguments:args error:aoErr];
}
@end
