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
    Value *retVal;
    retVal = [_value generateCodeInProgram:aProgram block:aBlock error:aoErr];
    retVal = aBlock.builder->CreateCall(aProgram.TQPrepareObjectForReturn, retVal);
    aBlock.builder->CreateCall(aProgram.objc_autoreleasePoolPop, aBlock.autoreleasePool);
    retVal = aBlock.builder->CreateCall(aProgram.TQAutoreleaseObject, retVal);
    return aBlock.builder->CreateRet(retVal);
}
@end
