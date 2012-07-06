#import "TQNodeReturn.h"
#import "../TQProgram.h"
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
    Value *retVal;
    retVal = builder->CreateCall(aProgram.TQPrepareObjectForReturn, [_value generateCodeInProgram:aProgram
                                                                                            block:aBlock
                                                                                            error:aoErr]);
    builder->CreateCall(aProgram.objc_autoreleasePoolPop, aBlock.autoreleasePool);
    retVal = builder->CreateCall(aProgram.TQAutoreleaseObject, retVal);
    return builder->CreateRet(retVal);
}
@end
