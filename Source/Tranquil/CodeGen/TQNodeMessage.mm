#import "TQNodeMessage.h"
#import "TQNode+Private.h"
#import "TQProgram.h"
#import "TQNodeArgument.h"
#import "TQNodeVariable.h"
#import "TQNodeBlock.h"

using namespace llvm;

@implementation TQNodeMessage
@synthesize receiver=_receiver, arguments=_arguments, cascadedMessages=_cascadedMessages, receiverLLVMValue=_receiverLLVMValue;

+ (TQNodeMessage *)nodeWithReceiver:(TQNode *)aNode
{
    return [[[self alloc] initWithReceiver:aNode] autorelease];
}

- (id)init
{
    if(!(self = [super init]))
        return nil;

    _arguments = [NSMutableArray new];
    _cascadedMessages = [NSMutableArray new];

    return self;
}
- (id)initWithReceiver:(TQNode *)aNode
{
    if(!(self = [self init]))
        return nil;

    _receiver = [aNode retain];

    return self;
}

- (void)dealloc
{
    [_receiver release];
    [_arguments release];
    [_cascadedMessages release];
    [super dealloc];
}

- (BOOL)isEqual:(id)aOther
{
    if(![aOther isMemberOfClass:[self class]])
        return NO;
    return [_receiver isEqual:[aOther receiver]] && [_arguments isEqual:[aOther arguments]];
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
    else if((ref = [_cascadedMessages tq_referencesNode:aNode]))
        return ref;
    return nil;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    aBlock(_receiver);
    for(TQNode *node in _arguments) {
        aBlock(node);
    }
    for(TQNodeMessage *message in _cascadedMessages) {
        for(TQNode *node in message.arguments) {
            aBlock(node);
        }
    }
}

- (BOOL)replaceChildNodesIdenticalTo:(TQNode *)aNodeToReplace with:(TQNode *)aNodeToInsert
{
    BOOL success = NO;
    if(_receiver == aNodeToReplace) {
        self.receiver = aNodeToInsert;
        success |= YES;
    } else
        success |= [_receiver replaceChildNodesIdenticalTo:aNodeToReplace with:aNodeToInsert];
    for(TQNodeArgument *arg in _arguments) {
        success |= [arg replaceChildNodesIdenticalTo:aNodeToReplace with:aNodeToInsert];
    }
    return success;
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

- (NSString *)toString
{
    NSMutableString *out = [NSMutableString stringWithString:@"["];
    [out appendFormat:@"%@ ", [_receiver toString]];
    for(TQNodeArgument *arg in _arguments) {
        [out appendFormat:@"%@ ", [arg toString]];
    }
    [out appendString:@"]"];
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


- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock root:(TQNodeRootBlock *)aRoot
                         withArguments:(std::vector<llvm::Value*>)aArgs error:(NSError **)aoErr
{
    NSString *selStr = [self selector];
    BOOL needsAutorelease = NO;
    if([selStr hasPrefix:@"alloc"])
        needsAutorelease = YES;
    else if([selStr isEqualToString:@"copy"] || [selStr hasSuffix:@"Copy"])
        needsAutorelease = YES;
    else if([selStr isEqualToString:@"new"])
        needsAutorelease = YES;

    aArgs.insert(aArgs.begin(), [aProgram getSelector:selStr inBlock:aBlock root:aRoot]);
    aArgs.insert(aArgs.begin(), _receiverLLVMValue ? _receiverLLVMValue : [_receiver generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr]);


    Value *ret;
    if([_receiver isMemberOfClass:[TQNodeSuper class]])
        ret = aBlock.builder->CreateCall(aProgram.objc_msgSendSuper, aArgs);
    else {
        ret = aBlock.builder->CreateCall(aProgram.tq_msgSend, aArgs);
        if(needsAutorelease) {
            [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];
            ret = aBlock.builder->CreateCall(aProgram.objc_autoreleaseReturnValue, ret);
            ((CallInst *)ret)->addAttribute(~0, Attribute::NoUnwind);
        }
    }
    [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];

    Value *origRet = ret;
    for(TQNodeMessage *cascadedMessage in _cascadedMessages) {
        cascadedMessage.receiverLLVMValue = origRet;
        ret = [cascadedMessage generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    }
    return ret;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    Module *mod = aProgram.llModule;
    std::vector<Value*> args;
    for(TQNodeArgument *arg in _arguments) {
        if(!arg.passedNode)
            break;
        args.push_back([arg generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr]);
    }
    // From what I can tell having read the ABI spec for x86-64, it is safe to pass this added argument. TODO: verify this holds for ARM&x86
    // Sentinel argument to make variadic methods possible (without resorting to special cases in tq_msgsend, and using libffi; which would kill performance)
    //args.push_back(aBlock.builder->CreateLoad(mod->getOrInsertGlobal("TQNothing", aProgram.llInt8PtrTy), "sentinel"));

    return [self generateCodeInProgram:aProgram block:aBlock root:aRoot withArguments:args error:aoErr];
}

@end
