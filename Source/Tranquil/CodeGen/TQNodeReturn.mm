#import "TQNodeReturn.h"
#import "TQNode+Private.h"
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

- (void)dealloc
{
    [_value release];
    [super dealloc];
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

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    aBlock(_value);
}

- (BOOL)replaceChildNodesIdenticalTo:(TQNode *)aNodeToReplace with:(TQNode *)aNodeToInsert
{
    if(aNodeToReplace != _value)
        return NO;

    [aNodeToInsert retain];
    [_value release];
    _value = aNodeToInsert;

    return YES;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    Value *retVal;
    if(_value) {
        retVal = [_value generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        retVal = aBlock.builder->CreateCall(aProgram.TQPrepareObjectForReturn, retVal);
        [self _attachDebugInformationToInstruction:retVal inProgram:aProgram block:aBlock root:aRoot];
        [aBlock generateCleanupInProgram:aProgram];
        retVal = aBlock.builder->CreateCall(aProgram.objc_autoreleaseReturnValue, retVal);
        [self _attachDebugInformationToInstruction:retVal inProgram:aProgram block:aBlock root:aRoot];
    } else {
        [aBlock generateCleanupInProgram:aProgram];
        retVal = ConstantPointerNull::get(aProgram.llInt8PtrTy);
    }

    // Release variables created in this block up to this point (captured variables do not need to be released as they will be in the dispose helper)
    for(NSString *varName in aBlock.locals.allKeys) {
        if([aBlock.capturedVariables objectForKey:varName])
            continue;
        [[aBlock.locals objectForKey:varName] generateReleaseInProgram:aProgram block:aBlock root:aRoot];
    }

    if([aBlock.retType isEqualToString:@"v"])
        return aBlock.builder->CreateRetVoid();
    return aBlock.builder->CreateRet(retVal);
}
@end
