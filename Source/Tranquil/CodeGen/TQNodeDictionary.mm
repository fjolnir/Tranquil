#import "TQNodeDictionary.h"
#import "TQNode+Private.h"
#import "TQProgram.h"
#import "TQNodeBlock.h"
#import "TQNodeArgument.h"
#import "TQNodeVariable.h"
#import "TQNodeNil.h"

using namespace llvm;

@implementation TQNodeDictionary
@synthesize items=_items;

+ (TQNodeDictionary *)node
{
    return (TQNodeDictionary *)[super node];
}

- (void)dealloc
{
    [_items release];
    [super dealloc];
}

- (OFString *)description
{
    OFMutableString *out = [OFMutableString stringWithString:@"<dict@["];
    for(TQNode *key in _items) {
        [out appendFormat:@"%@ => %@, ", key, [_items objectForKey:key]];
    }
    [out appendString:@"]>"];
    return out;
}
- (OFString *)toString
{
    OFMutableString *out = [OFMutableString stringWithString:@"["];
    for(TQNode *key in _items) {
        [out appendFormat:@"%@ => %@, ", [key toString], [[_items objectForKey:key] toString]];
    }
    [out appendString:@"]"];
    return out;
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    TQNode *ref = nil;

    if([self isEqual:aNode])
        return self;
    OFEnumerator *keyEnum = [_items keyEnumerator];
    TQNode *key;
    while(key = [keyEnum nextObject]) {
        if((ref = [key referencesNode:aNode]))
            return ref;
        else if((ref = [[_items objectForKey:key] referencesNode:aNode]))
            return ref;
    }

    return nil;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    OFEnumerator *keyEnum = [_items keyEnumerator];
    TQNode *key;
    while(key = [keyEnum nextObject]) {
        aBlock(key);
        aBlock([_items objectForKey:key]);
    }
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(TQError **)aoErr
{
    Module *mod = aProgram.llModule;

    std::vector<Value *>args;
    args.push_back(mod->getOrInsertGlobal("OBJC_CLASS_$_OFMutableDictionary", aProgram.llInt8Ty));
    args.push_back(aBlock.builder->CreateLoad(mod->getOrInsertGlobal("TQDictWithObjectsAndKeysSel", aProgram.llInt8PtrTy)));
    TQNode *value;

    int count = 0;
    for(TQNode *key in _items) {
        ++count;
        assert(![key isKindOfClass:[TQNodeNil class]]);
        value = [_items objectForKey:key];
        args.push_back([value generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr]);
        if(*aoErr) return NULL;
        args.push_back([key generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr]);
        if(*aoErr) return NULL;
    }
    args.push_back(aBlock.builder->CreateLoad(mod->getOrInsertGlobal("TQNothing", aProgram.llInt8PtrTy)));

    CallInst *call = aBlock.builder->CreateCall(aProgram.objc_msgSend, args);
    [self _attachDebugInformationToInstruction:call inProgram:aProgram block:aBlock root:aRoot];
    return call;
}

@end

