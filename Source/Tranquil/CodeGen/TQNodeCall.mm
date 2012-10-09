#import "TQNodeCall.h"
#import "TQNode+Private.h"
#import "TQProgram.h"
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
    _arguments = [NSMutableArray new];

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
- (NSString *)toString
{
    return [NSString stringWithFormat:@"%@()", [_callee toString]];
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


- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    aBlock(_callee);
    for(TQNode *node in [[_arguments copy] autorelease]) {
        aBlock(node);
    }
}

- (BOOL)replaceChildNodesIdenticalTo:(TQNode *)aNodeToReplace with:(TQNode *)aNodeToInsert
{
    BOOL success = NO;
    if(_callee == aNodeToReplace) {
        self.callee = aNodeToInsert;
        success |= YES;
    } else
        success |= [_callee replaceChildNodesIdenticalTo:aNodeToReplace with:aNodeToInsert];

    NSIndexSet *indices = [_arguments indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
        return (BOOL)(obj == aNodeToReplace);
    }];
    success |= [indices count] > 0;
    [indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [_arguments replaceObjectAtIndex:idx withObject:aNodeToInsert];
    }];
    return success;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock root:(TQNodeRootBlock *)aRoot
                         withArguments:(std::vector<llvm::Value*>)aArgs error:(NSError **)aoErr
{
    Value *callee = [_callee generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
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

    Value *ret = aBlock.builder->CreateCall(dispatcher, aArgs);
    [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];
    return ret;
}


- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    IRBuilder<> *builder = aBlock.builder;

    std::vector<Value*> args;
    for(TQNodeArgument *arg in _arguments) {
        args.push_back([arg generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr]);
    }
    return [self generateCodeInProgram:aProgram block:aBlock root:aRoot withArguments:args error:aoErr];
}
@end
