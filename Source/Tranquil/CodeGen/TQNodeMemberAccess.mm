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

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    aBlock(_receiver);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<acc@ %@#%@>", _receiver, _property];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    IRBuilder<> *builder = aBlock.builder;
	Value *key = [aProgram getGlobalStringPtr:_property inBlock:aBlock];
    Value *object = [_receiver generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    return builder->CreateCall2(aProgram.TQValueForKey, object, key);
}

- (llvm::Value *)store:(llvm::Value *)aValue
             inProgram:(TQProgram *)aProgram
                 block:(TQNodeBlock *)aBlock
                  root:(TQNodeRootBlock *)aRoot
                 error:(NSError **)aoErr
{
    IRBuilder<> *builder = aBlock.builder;
	//NSString *keyVarName = [NSString stringWithFormat:@"TQPropertyKey_%@", _property];

    //Value *key = aProgram.llModule->getGlobalVariable([keyVarName UTF8String], true);
	//TQLog(@"var for %@: %p", keyVarName, key);
	//if(!key)
		//key = builder->CreateGlobalString([_property UTF8String], [keyVarName UTF8String]);
    //Value *zero = ConstantInt::get(Type::getInt32Ty(aProgram.llModule->getContext()), 0);
    //Value *Args[] = { zero, zero };
    //key = builder->CreateInBoundsGEP(key, Args, );
	Value *key = [aProgram getGlobalStringPtr:_property inBlock:aBlock];
    Value *object = [_receiver generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    return builder->CreateCall3(aProgram.TQSetValueForKey, object, key, aValue);
}
@end
