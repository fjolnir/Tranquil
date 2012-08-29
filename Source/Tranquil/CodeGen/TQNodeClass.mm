#import "TQNodeClass.h"
#import "TQNode+Private.h"
#import "TQNodeMethod.h"
#import "TQNodeMessage.h"
#import "TQProgram.h"

using namespace llvm;

@implementation TQNodeClass
@synthesize name=_name, superClassName=_superClassName, classMethods=_classMethods, instanceMethods=_instanceMethods,
    classPtr=_classPtr, onLoadMessages=_onloadMessages;

+ (TQNodeClass *)nodeWithName:(NSString *)aName
{
    return [[[self alloc] initWithName:aName] autorelease];
}

- (id)initWithName:(NSString *)aName
{
    if(!(self = [super init]))
        return nil;

    _name = [aName retain];

    _classMethods    = [NSMutableArray new];
    _instanceMethods = [NSMutableArray new];
    _onloadMessages  = [NSMutableArray new];

    return self;
}

- (void)dealloc
{
    [_name release];
    [_superClassName release];
    [_classMethods release];
    [_instanceMethods release];
    [_onloadMessages release];
    [super dealloc];
}

- (NSString *)description
{
    NSMutableString *out = [NSMutableString stringWithFormat:@"<cls@ class %@", _name];
    if(_superClassName)
        [out appendFormat:@" < %@", _superClassName];
    [out appendString:@"\n"];

    for(TQNodeMethod *meth in _classMethods) {
        [out appendFormat:@"%@\n", meth];
    }
    if(_classMethods.count > 0 && _instanceMethods.count > 0)
        [out appendString:@"\n"];
    for(TQNodeMethod *meth in _instanceMethods) {
        [out appendFormat:@"%@\n", meth];
    }

    [out appendString:@"end>"];
    return out;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    if(_classPtr) {
        Value *ret = aBlock.builder->CreateCall2(aProgram.TQGetOrCreateClass, [aProgram getGlobalStringPtr:_name inBlock:aBlock], ConstantPointerNull::get(aProgram.llInt8PtrTy));
        [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];
        return ret;
    }

    // -- Type definitions
    // -- Method definitions
    IRBuilder<> *builder = aBlock.builder;

    Value *name       = [aProgram getGlobalStringPtr:_name inBlock:aBlock];
    Value *superName  = [aProgram getGlobalStringPtr:_superClassName ? _superClassName : @"TQObject" inBlock:aBlock];

    _classPtr = builder->CreateCall2(aProgram.TQGetOrCreateClass, name, superName);
    [self _attachDebugInformationToInstruction:_classPtr inProgram:aProgram block:aBlock root:aRoot];

    // Add the methods for the class
    for(TQNodeMethod *method in [_classMethods arrayByAddingObjectsFromArray:_instanceMethods]) {
        [method generateCodeInProgram:aProgram block:aBlock class:self root:aRoot error:aoErr];
        if(*aoErr) return NULL;
    }

    // Execute any onload messages
    for(TQNodeMessage *msg in _onloadMessages) {
        [msg generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    }

    return _classPtr;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    for(TQNode *node in _classMethods) {
        aBlock(node);
    }
    for(TQNode *node in _instanceMethods) {
        aBlock(node);
    }
}

- (id)referencesNode:(TQNode *)aNode
{
    return nil;
}
@end
