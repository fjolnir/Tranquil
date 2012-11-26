#import "TQNodeMemberAccess.h"
#import "TQNode+Private.h"
#import "TQNodeString.h"
#import "TQNodeBlock.h"
#import "TQNodeVariable.h"
#import "TQProgram.h"

using namespace llvm;

@implementation TQNodeMemberAccess
@synthesize ivarName=_ivarName;

+ (TQNodeMemberAccess *)nodeWithName:(NSString *)aName
{
    return [[[self alloc] initWithName:aName] autorelease];
}

- (id)initWithName:(NSString *)aName
{
    if(!(self = [super init]))
        return nil;

    _ivarName = [aName retain];

    return self;
}

- (void)dealloc
{
    [_ivarName release];
    [super dealloc];
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    if([aNode isEqual:self])
        return self;
    else if([aNode isEqual:[TQNodeSelf node]])
        return [TQNodeSelf node];
    return nil;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    // Nothing to iterate
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<acc@ @%@>", _ivarName];
}
- (NSString *)toString
{
    return [NSString stringWithFormat:@"ivar_%@", _ivarName];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    IRBuilder<> *builder = aBlock.builder;
    Value *key = [[TQNodeConstString nodeWithString:_ivarName] generateCodeInProgram:aProgram
                                                                               block:aBlock
                                                                                root:aRoot
                                                                               error:aoErr];
    Value *object = [[TQNodeSelf node] generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    Value *ret = builder->CreateCall2(aProgram.TQValueForKey, object, key);
    [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];
    return ret;
}

- (llvm::Value *)store:(llvm::Value *)aValue
             inProgram:(TQProgram *)aProgram
                 block:(TQNodeBlock *)aBlock
                  root:(TQNodeRootBlock *)aRoot
                 error:(NSError **)aoErr
{
    IRBuilder<> *builder = aBlock.builder;

    Value *key = [[TQNodeConstString nodeWithString:_ivarName] generateCodeInProgram:aProgram
                                                                               block:aBlock
                                                                                root:aRoot
                                                                               error:aoErr];
    Value *object = [[TQNodeSelf node] generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    Value *ret = builder->CreateCall3(aProgram.TQSetValueForKey, object, key, aValue);
    [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];
    return ret;
}
@end
