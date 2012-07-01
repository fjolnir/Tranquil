#import "TQNodeMemberAccess.h"
#import "TQNodeBlock.h"
#import "TQProgram.h"

using namespace llvm;

@implementation TQNodeMemberAccess
@synthesize receiver=_receiver, property=_property;

+ (TQNodeMemberAccess *)nodeWithReceiver:(TQNode *)aReceiver property:(NSString *)aProperty
{
    return [[[self alloc] initWithReceiver:aReceiver property:aProperty] autorelease];
}

- (id)initWithReceiver:(TQNode *)aReceiver property:(NSString *)aProperty
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


- (NSString *)description
{
    return [NSString stringWithFormat:@"<acc@ %@#%@>", _receiver, _property];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                 error:(NSError **)aoError
{
    IRBuilder<> *builder = aBlock.builder;
    Value *key = builder->CreateGlobalStringPtr([_property UTF8String]);
    Value *object = [_receiver generateCodeInProgram:aProgram block:aBlock error:aoError];
    return builder->CreateCall2(aProgram.TQValueForKey, object, key);
}

- (llvm::Value *)store:(llvm::Value *)aValue
             inProgram:(TQProgram *)aProgram
                 block:(TQNodeBlock *)aBlock
                 error:(NSError **)aoError
{
    IRBuilder<> *builder = aBlock.builder;
    Value *key = builder->CreateGlobalStringPtr([_property UTF8String]);
    Value *object = [_receiver generateCodeInProgram:aProgram block:aBlock error:aoError];
    return builder->CreateCall3(aProgram.TQSetValueForKey, object, key, aValue);
}
@end
