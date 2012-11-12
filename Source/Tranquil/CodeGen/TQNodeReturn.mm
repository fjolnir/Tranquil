#import "TQNodeReturn.h"
#import "TQNode+Private.h"
#import "TQProgram.h"
#import "TQNodeVariable.h"
#import "TQNodeBlock.h"
#import "TQNodeMessage.h"
#import "TQNodeCall.h"
#import "TQNodeArgument.h"
#import "TQNodeArgumentDef.h"

using namespace llvm;

@implementation TQNodeReturn
@synthesize value=_value, depth=_depth;
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

- (OFString *)description
{
    return [OFString stringWithFormat:@"<ret@ %@>", _value];
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
                                 error:(TQError **)aoErr
{
    Value *retVal;
    if(_value) {
        retVal = [_value generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        retVal = aBlock.builder->CreateCall(aProgram.TQPrepareObjectForReturn, retVal);
        ((CallInst *)retVal)->addAttribute(~0, Attribute::NoUnwind);
        [self _attachDebugInformationToInstruction:retVal inProgram:aProgram block:aBlock root:aRoot];
        if(_depth == 0)
            [aBlock generateCleanupInProgram:aProgram];
        else {
            // Non-local return
            TQNodeBlock *destBlock = aBlock.parent;
            for(int i = 1; i < _depth; ++i) {
                destBlock = destBlock.parent;
            }
            TQAssert(destBlock, @"Tried to return too far up!");

            Value *target    = [destBlock.nonLocalReturnTarget generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
            Value *targetPtr = [destBlock.literalPtr generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
            Value *thread    = [destBlock.nonLocalReturnThread generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
            Value *jmpBuf = aBlock.builder->CreateCall4(aProgram.TQGetNonLocalReturnJumpTarget, thread, targetPtr, target, retVal);
            aBlock.builder->CreateCall2(aProgram.longjmp, jmpBuf, ConstantInt::get(aProgram.llInt32Ty, 0));
        }

        retVal = aBlock.builder->CreateCall(aProgram.objc_autoreleaseReturnValue, retVal);
        ((CallInst *)retVal)->addAttribute(~0, Attribute::NoUnwind);
        [self _attachDebugInformationToInstruction:retVal inProgram:aProgram block:aBlock root:aRoot];
    } else {
        [aBlock generateCleanupInProgram:aProgram];
        retVal = ConstantPointerNull::get(aProgram.llInt8PtrTy);
    }

    // Release variables created in this block up to this point (captured variables do not need to be released as they will be in the dispose helper)
    for(OFString *varName in aBlock.locals.allKeys) {
        unsigned long argIdx = OF_NOT_FOUND;
        for(int i = 0; i < [aBlock.arguments count]; ++i) {
            if([[[aBlock.arguments objectAtIndex:i] name] isEqual:varName]) {
                argIdx = i;
                break;
            }
        }
        if([aBlock.capturedVariables objectForKey:varName] || (argIdx != OF_NOT_FOUND && [[aBlock.arguments objectAtIndex:argIdx] unretained]))
            continue;
        [[aBlock.locals objectForKey:varName] generateReleaseInProgram:aProgram block:aBlock root:aRoot];
    }

    if([aBlock.retType isEqual:@"v"])
        return aBlock.builder->CreateRetVoid();
    return aBlock.builder->CreateRet(retVal);
}
@end
