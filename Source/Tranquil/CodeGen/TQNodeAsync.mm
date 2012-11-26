#import "TQNodeAsync.h"
#import "TQNode+Private.h"
#import "TQNodeBlock.h"
#import "TQNodeCall.h"
#import "TQProgram.h"
#import "TQNodeOperator.h"
#import "TQNodeCustom.h"
#import "TQNodeArgument.h"
#import "TQNodeVariable.h"
#import "TQNodeMessage.h"

using namespace llvm;

@implementation TQNodeAsync
@synthesize expression=_expression;

+ (TQNodeAsync *)nodeWithExpression:(TQNode *)aExpression
{
    TQNodeAsync *ret = (TQNodeAsync *)[super node];
    ret->_expression = [aExpression retain];
    return ret;
}
- (void)dealloc
{
    [_expression release];
    [super dealloc];
}

- (BOOL)isEqual:(id)b
{
    if(![b isMemberOfClass:[self class]])
        return NO;
    return [_expression isEqual:[b expression]];
}

- (id)referencesNode:(TQNode *)aNode
{
    if([aNode isEqual:self])
        return self;
    return [_expression referencesNode:aNode];
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    aBlock(_expression);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<async: %@>", _expression];
}

- (llvm::Value *)_generateDispatchBlockWithPromise:(llvm::Value *)aPromise
                                         inProgram:(TQProgram *)aProgram
                                             block:(TQNodeBlock *)aBlock
                                              root:(TQNodeRootBlock *)aRoot
                                             error:(NSError **)aoErr
{
    TQNodeVariable *promiseVar = [TQNodeVariable tempVar];
    [promiseVar store:aPromise inProgram:aProgram block:aBlock root:aRoot error:aoErr];

    [aBlock createDispatchGroupInProgram:aProgram];

    if([_expression isKindOfClass:[TQNodeCall class]]) {
        TQNodeCall *callToPrepare = (TQNodeCall *)_expression;
        // In the case of a block call we must synchronously evaluate the parameters before
        // asynchronously dispatching the call itself
        NSMutableArray *origArgs = [callToPrepare.arguments copy];
        callToPrepare.arguments = [NSMutableArray array];
        for(TQNodeArgument *arg in origArgs) {
            Value *val = [arg generateCodeInProgram:aProgram
                                              block:aBlock
                                               root:aRoot
                                              error:aoErr];
            TQNodeVariable *tempVar = [TQNodeVariable tempVar];
            [tempVar store:val inProgram:aProgram block:aBlock root:aRoot error:aoErr];
            [callToPrepare.arguments addObject:tempVar];
        }
        [origArgs release];
    }

    if([_expression isKindOfClass:[TQNodeBlock class]])
        _expression = [TQNodeCall nodeWithCallee:_expression];

    TQNodeBlock *block = [TQNodeBlock node];
    block.retType = @"v";
    block.lineNumber = self.lineNumber;
    TQNodeMessage *resolver = [TQNodeMessage nodeWithReceiver:promiseVar];
    [[resolver arguments] addObject:[TQNodeArgument nodeWithPassedNode:_expression selectorPart:@"fulfillWith"]];
    [block.statements addObject:resolver];

    return [block generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
}

- (llvm::Function *)_dispatchFunctionWithProgram:(TQProgram *)aProgram
{
    return aProgram.dispatch_group_async;
}
- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    Module *mod = aProgram.llModule;
    Value *pKls = mod->getOrInsertGlobal("OBJC_CLASS_$_TQPromise", aProgram.llInt8Ty);
    Value *pSel = [aProgram getSelector:@"promise" inBlock:aBlock root:aRoot];

    Value *promise = aBlock.builder->CreateCall2(aProgram.objc_msgSend, pKls, pSel);
    Value *compiledBlock = [self _generateDispatchBlockWithPromise:promise
                                                         inProgram:aProgram
                                                             block:aBlock
                                                              root:aRoot
                                                             error:aoErr];
    Value *call = aBlock.builder->CreateCall3([self _dispatchFunctionWithProgram:aProgram], aBlock.dispatchGroup,
                                              aBlock.builder->CreateLoad(aProgram.globalQueue), compiledBlock);
    [self _attachDebugInformationToInstruction:call inProgram:aProgram block:aBlock root:aRoot];
    return promise;
}
@end

@implementation TQNodeWait
+ (TQNodeWait *)node
{
    return (TQNodeWait *)[super node];
}

- (BOOL)isEqual:(id)b
{
    return [b isMemberOfClass:[self class]];
}

- (id)referencesNode:(TQNode *)aNode
{
    return [aNode isEqual:self] ? self : nil;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    // Nothing to iterate
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    if(aBlock.dispatchGroup) {
        Value *call = aBlock.builder->CreateCall2(aProgram.dispatch_group_wait, aBlock.dispatchGroup, ConstantInt::get(aProgram.llInt64Ty, DISPATCH_TIME_FOREVER));
        [self _attachDebugInformationToInstruction:call inProgram:aProgram block:aBlock root:aRoot];
    }
    return ConstantPointerNull::get(aProgram.llInt8PtrTy);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<wait>"];
}
@end

@implementation TQNodeWhenFinished
+ (TQNodeWhenFinished *)nodeWithExpression:(TQNode *)aExpression;
{
    return (TQNodeWhenFinished *)[super nodeWithExpression:aExpression];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<whenFinished: %@>", self.expression];
}

- (llvm::Function *)_dispatchFunctionWithProgram:(TQProgram *)aProgram
{
    return aProgram.dispatch_group_notify;
}

@end
