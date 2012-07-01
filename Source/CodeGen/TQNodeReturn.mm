#import "TQNodeReturn.h"
#import "TQProgram.h"
#import "TQNodeVariable.h"
#import "TQNodeBlock.h"
#import "TQNodeMessage.h"
#import "TQNodeCall.h"
#import "TQNodeArgument.h"

using namespace llvm;

@implementation TQNodeReturn
@synthesize value=_value;
+ (TQNodeReturn *)nodeWithValue:(TQNode *)aValue
{
    return [[[self alloc] initWithValue:aValue] autorelease];
}

- (id)initWithValue:(TQNode *)aValue
{
    if(!(self = [super init]))
        return nil;

    _value = [aValue retain];

    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<ret@ %@>", _value];
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    TQNode *ref = nil;
    if([aNode isEqual:self])
        return self;
    else if((ref = [_value referencesNode:aNode]))
        return ref;
    return nil;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
    IRBuilder<> *builder = aBlock.builder;

    // Release any blocks created inside the block we're returning from (Unless we're returning it)
    //for(TQNode *stmt in aBlock.statements) {
        //if(![stmt isKindOfClass:[TQNodeBlock class]])
            //continue;
        //TQNodeBlock *blk = (TQNodeBlock*)stmt;
        
    //}
    
    // Evaluate retain the value or if it's a call, it's arguments before popping the block's autorelease pool
    Value *retVal;
    std::vector<Value*> args;
    BOOL isTailCall = [_value isKindOfClass:[TQNodeCall class]] || [_value isKindOfClass:[TQNodeMessage class]];
    if(isTailCall) {
        Value *arg;
        for(TQNodeArgument *argNode in [(TQNodeCall *)_value arguments]) {
            arg = [argNode generateCodeInProgram:aProgram block:aBlock error:aoErr];
            builder->CreateCall(aProgram.TQRetainObject, arg);
            args.push_back(arg);
        }
    } else {
        retVal = builder->CreateCall(aProgram.TQRetainObject, [_value generateCodeInProgram:aProgram
                                                                                      block:aBlock
                                                                                      error:aoErr]);
    }
    // Pop
    builder->CreateCall(aProgram.objc_autoreleasePoolPop, aBlock.autoreleasePool);
    
    // Return
    if(isTailCall)
        retVal = [(TQNodeCall *)_value generateCodeInProgram:aProgram block:aBlock withArguments:args error:aoErr];
    else
        retVal = builder->CreateCall(aProgram.TQAutoreleaseObject, retVal);
    //Value *retVal = [_value generateCodeInProgram:aProgram block:aBlock error:aoError];
    // If the returned instruction is not a call, then it's our responsibility to prepare for return (For example to copy a block
    // to the heap if necessary)
    if(![_value isKindOfClass:[TQNodeMessage class]] && ![_value isKindOfClass:[TQNodeCall class]])
        retVal = builder->CreateCall(aProgram.TQPrepareObjectForReturn, retVal);
    //else if(isTailCall && ![aBlock isKindOfClass:[TQNodeRootBlock class]])
        //((CallInst*)retVal)->setTailCall(true);
    return builder->CreateRet(retVal);
}
@end
