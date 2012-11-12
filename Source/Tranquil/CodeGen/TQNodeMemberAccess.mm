#import "TQNodeMemberAccess.h"
#import "TQNode+Private.h"
#import "TQNodeBlock.h"
#import "TQNodeString.h"
#import "TQProgram.h"

using namespace llvm;

@implementation TQNodeMemberAccess
@synthesize receiver=_receiver, property=_property;

+ (TQNodeMemberAccess *)nodeWithReceiver:(TQNode *)aReceiver property:(OFString *)aProperty
{
    return [[[self alloc] initWithReceiver:aReceiver property:aProperty] autorelease];
}

- (id)initWithReceiver:(TQNode *)aReceiver property:(OFString *)aProperty
{
    if(!(self = [super init]))
        return nil;

    _receiver = [aReceiver retain];
    _property = [aProperty retain];

    return self;
}

- (void)dealloc
{
    [_receiver release];
    [_property release];
    [super dealloc];
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    TQNode *ref = nil;
    if([aNode isEqual:self])
        ref = self;
    else if((ref = [_receiver referencesNode:aNode]))
        return ref;
    return ref;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    aBlock(_receiver);
}

- (OFString *)description
{
    return [OFString stringWithFormat:@"<acc@ %@#%@>", _receiver, _property];
}
- (OFString *)toString
{
    return [OFString stringWithFormat:@"%@#%@>", [_receiver toString], _property];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(TQError **)aoErr
{
    IRBuilder<> *builder = aBlock.builder;
    Value *key = [[TQNodeConstString nodeWithString:_property] generateCodeInProgram:aProgram
                                                                               block:aBlock
                                                                                root:aRoot
                                                                               error:aoErr];
    Value *object = [_receiver generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    Value *ret = builder->CreateCall2(aProgram.TQValueForKey, object, key);
    [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];
    return ret;
}

- (llvm::Value *)store:(llvm::Value *)aValue
             inProgram:(TQProgram *)aProgram
                 block:(TQNodeBlock *)aBlock
                  root:(TQNodeRootBlock *)aRoot
                 error:(TQError **)aoErr
{
    IRBuilder<> *builder = aBlock.builder;

    Value *key = [[TQNodeConstString nodeWithString:_property] generateCodeInProgram:aProgram
                                                                               block:aBlock
                                                                                root:aRoot
                                                                               error:aoErr];
    Value *object = [_receiver generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    Value *ret = builder->CreateCall3(aProgram.TQSetValueForKey, object, key, aValue);
    [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];
    return ret;
}
@end
