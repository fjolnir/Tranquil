#import "TQNodeMessage.h"
#import "TQNode+Private.h"
#import "TQProgram.h"
#import "TQNodeArgument.h"
#import "TQNodeVariable.h"
#import "TQNodeBlock.h"
#import "TQNodeCustom.h"
#import "../Runtime/NSString+TQAdditions.h"

using namespace llvm;

@interface TQNodeMessage ()
@property(readwrite) llvm::Value *receiverLLVMValue; // If this is set, the receiver node is ignored
@end

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

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    Module *mod = aProgram.llModule;
    std::vector<Value*> args;

    NSString *selStr = [self selector];
    BOOL needsAutorelease = NO;
    if([selStr hasPrefix:@"alloc"])
        needsAutorelease = YES;
    else if([selStr isEqualToString:@"copy"] || [selStr hasSuffix:@"Copy"])
        needsAutorelease = YES;
    else if([selStr isEqualToString:@"new"])
        needsAutorelease = YES;

    Value *receiver = _receiverLLVMValue ?: [_receiver generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    if(*aoErr)
        return NULL;
    args.push_back(receiver);
    args.push_back([aProgram getSelector:selStr inBlock:aBlock root:aRoot]);

    for(TQNodeArgument *arg in _arguments) {
        if(!arg.passedNode)
            break;
        Value *argVal = [arg generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        if(*aoErr)
            return NULL;
        args.push_back(argVal);
    }
    // From what I can tell having read the ABI spec for x86-64, it is safe to pass this added argument. TODO: verify this holds for ARM&x86
    // Sentinel argument to make variadic methods possible (without resorting to special cases in tq_msgsend, and using libffi; which would kill performance)
    //args.push_back(aBlock.builder->CreateLoad(mod->getOrInsertGlobal("TQNothing", aProgram.llInt8PtrTy), "sentinel"));
    Value *ret;
    if([_receiver isMemberOfClass:[TQNodeSuper class]])
        ret = aBlock.builder->CreateCall(aProgram.objc_msgSendSuper, args);
    else {
        ret = aBlock.builder->CreateCall(aProgram.tq_msgSend, args);
        if(needsAutorelease) {
            [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];
            ret = aBlock.builder->CreateCall(aProgram.objc_autoreleaseReturnValue, ret);
            ((CallInst *)ret)->addAttribute(~0, Attribute::NoUnwind);
        }
    }
    [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];

    Value *origRet = ret;
    for(TQNodeMessage *cascadedMessage in _cascadedMessages) {
        cascadedMessage.receiverLLVMValue = receiver;
        ret = [cascadedMessage generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        if(!ret)
            return NULL;
    }
    return ret;
}

- (llvm::Value *)store:(llvm::Value *)aValue
             inProgram:(TQProgram *)aProgram
                 block:(TQNodeBlock *)aBlock
                  root:(TQNodeRootBlock *)aRoot
                 error:(NSError **)aoErr
{
    // "Storing" to a message just means to transform the message to it's setter variant
    TQAssertSoft(![[_arguments objectAtIndex:0] passedNode], kTQSyntaxErrorDomain, kTQInvalidAssignee, NULL, @"Tried to assign to a keyword message (The grammar doesn't even allow that to happen, how'd you get here?");
    NSString *selector = [NSString stringWithFormat:@"set%@", [[[_arguments objectAtIndex:0] selectorPart] stringByCapitalizingFirstLetter]];
    TQNodeCustom *valWrapper = [TQNodeCustom nodeReturningValue:aValue];
    TQNodeMessage *setterMsg = [TQNodeMessage nodeWithReceiver:_receiver];
    [setterMsg.arguments addObject:[TQNodeArgument nodeWithPassedNode:valWrapper selectorPart:selector]];
    if([setterMsg generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr])
        return aValue;
    else
        return NULL;
}

@end
