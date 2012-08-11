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
    if(_value) {
        retVal = [_value generateCodeInProgram:aProgram block:aBlock error:aoErr];
        retVal = aBlock.builder->CreateCall(aProgram.TQPrepareObjectForReturn, retVal);
        aBlock.builder->CreateCall(aProgram.objc_autoreleasePoolPop, aBlock.autoreleasePool);
        retVal = aBlock.builder->CreateCall(aProgram.objc_autoreleaseReturnValue, retVal);
    } else
        retVal = ConstantPointerNull::get(aProgram.llInt8PtrTy);

    // Release variables created in this block up to this point (captured variables do not need to be released as they will be in the dispose helper)
    for(NSString *varName in aBlock.locals.allKeys) {
        if([aBlock.capturedVariables objectForKey:varName])
            continue;
        TQNodeVariable *var = [aBlock.locals objectForKey:varName];
        [var generateReleaseInProgram:aProgram block:aBlock];
    }

    return aBlock.builder->CreateRet(retVal);
}
@end
