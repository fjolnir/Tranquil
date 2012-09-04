#import "TQNodeAsync.h"
#import "TQNode+Private.h"
#import "TQNodeBlock.h"
#import "TQNodeCall.h"
#import "TQProgram.h"
#import "TQNodeOperator.h"
#import "TQNodeCustom.h"
#import "TQNodeArgument.h"
#import "TQNodeVariable.h"

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

- (llvm::Value *)_generateDispatchBlockInProgram:(TQProgram *)aProgram
                                           block:(TQNodeBlock *)aBlock
                                            root:(TQNodeRootBlock *)aRoot
                                           error:(NSError **)aoErr
{
    [aBlock createDispatchGroupInProgram:aProgram];

    TQNodeBlock *block = (TQNodeBlock *)_expression;
    TQNodeCall *callToPrepare = NULL;
    // In case of an assignment to a subscript, we need to evaluate the subscript synchronously
    if([_expression isKindOfClass:[TQNodeOperator class]]) {
        TQNodeOperator *op = (TQNodeOperator *)_expression;
        if(op.type == kTQOperatorAssign) {
            if([op.left isKindOfClass:[TQNodeOperator class]] && [(TQNodeOperator *)op.left type] == kTQOperatorSubscript) {
                TQNodeOperator *subscr = (TQNodeOperator *)op.left;
                Value *subscriptVal = [subscr.right generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
                TQNodeVariable *tempVar = [TQNodeVariable tempVar];
                [tempVar store:subscriptVal inProgram:aProgram block:aBlock root:aRoot error:aoErr];
                subscr.right = tempVar;
            }
            if([op.right isKindOfClass:[TQNodeCall class]])
                callToPrepare = (TQNodeCall *)op.right;
        }
    }
    if([_expression isKindOfClass:[TQNodeCall class]])
        callToPrepare = (TQNodeCall *)_expression;

    if(callToPrepare) {
        // In the case of a block call we must synchronously evaluate the parameters before
        // asynchronously dispatching the block itself
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

    if(![_expression isKindOfClass:[TQNodeBlock class]]) {
        block = [TQNodeBlock node];
        block.lineNumber = self.lineNumber;
        [block.statements addObject:_expression];
    } else if([block.arguments count] != 1) {
        // Ensure the block is called with nil args
        block = [TQNodeBlock node];
        block.lineNumber = self.lineNumber;
        [block.statements addObject:[TQNodeCall nodeWithCallee:_expression]];
    }
    block.retType = @"v";
    return [block generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    Value *compiledBlock = [self _generateDispatchBlockInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    Value *call = aBlock.builder->CreateCall3(aProgram.dispatch_group_async, aBlock.dispatchGroup,
                                              aBlock.builder->CreateLoad(aProgram.globalQueue), compiledBlock);
    [self _attachDebugInformationToInstruction:call inProgram:aProgram block:aBlock root:aRoot];
    return NULL;
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
    return NULL;
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

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    Value *compiledBlock = [self _generateDispatchBlockInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    Value *call = aBlock.builder->CreateCall3(aProgram.dispatch_group_notify, aBlock.dispatchGroup,
                                              aBlock.builder->CreateLoad(aProgram.globalQueue), compiledBlock);
    [self _attachDebugInformationToInstruction:call inProgram:aProgram block:aBlock root:aRoot];
    return NULL;
}
@end
