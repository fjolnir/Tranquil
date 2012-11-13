#import "TQNodeArray.h"
#import "TQNode+Private.h"
#import "TQProgram.h"
#import "TQNodeBlock.h"
#import "TQNodeArgument.h"
#import "TQNodeVariable.h"

using namespace llvm;

@implementation TQNodeArray
@synthesize items=_items;

+ (TQNodeArray *)node
{
    return (TQNodeArray *)[super node];
}

- (void)dealloc
{
    [_items release];
    [super dealloc];
}

- (OFString *)description
{
    OFMutableString *out = [OFMutableString stringWithString:@"<array@["];
    for(TQNode *item in _items) {
        [out appendFormat:@"%@, ", item];
    }
    [out appendString:@"]>"];
    return out;
}
- (OFString *)toString
{
    OFMutableString *out = [OFMutableString stringWithString:@"["];
    for(TQNode *item in _items) {
        [out appendFormat:@"%@, ", [item toString]];
    }
    [out appendString:@"]"];
    return out;
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    TQNode *ref = nil;

    if([self isEqual:aNode])
        return self;
    if((ref = [_items tq_referencesNode:aNode]))
        return ref;

    return nil;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    for(TQNode *node in _items) {
        aBlock(node);
    }
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(TQError **)aoErr
{
    Module *mod = aProgram.llModule;

    std::vector<Value *>args;
    args.push_back(mod->getOrInsertGlobal("OBJC_CLASS_$_OFMutableArray", aProgram.llInt8Ty));
    args.push_back(aBlock.builder->CreateLoad(mod->getOrInsertGlobal("TQArrayWithObjectsSel", aProgram.llInt8PtrTy)));
    for(TQNode *item in _items) {
        args.push_back([item generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr]);
        if(*aoErr)
            return NULL;
    }
    args.push_back(aBlock.builder->CreateLoad(mod->getOrInsertGlobal("TQNothing", aProgram.llInt8PtrTy)));

    Value *ret = aBlock.builder->CreateCall(aProgram.objc_msgSend, args);
    [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];
    return ret;
}

@end
