#import "TQNodeString.h"
#import "../TQProgram.h"

using namespace llvm;

@implementation TQNodeString
@synthesize value=_value;

+ (TQNodeString *)nodeWithString:(NSMutableString *)aStr
{
    TQNodeString *node = [self new];
    node.value = aStr;
    return [node autorelease];
}

- (id)init
{
    if(!(self = [super init]))
        return nil;
    _embeddedValues = [NSMutableArray new];
    return self;
}

- (void)dealloc
{
    [_value release];
    [_embeddedValues release];
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<str@ \"%@\">", _value];
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    // All string refs must be unique since they are mutable
    TQNode *ref = [_embeddedValues tq_referencesNode:aNode];
    if(ref)
        return ref;
    return nil;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    for(TQNode *node in _embeddedValues) {
        aBlock(node);
    }
}

- (BOOL)replaceChildNodesIdenticalTo:(TQNode *)aNodeToReplace with:(TQNode *)aNodeToInsert
{
    NSUInteger idx = [_embeddedValues indexOfObject:aNodeToReplace];
    if(idx == NSNotFound)
        return NO;
    [_embeddedValues replaceObjectAtIndex:idx withObject:aNodeToInsert];
    return NO;
}


- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    Module *mod = aProgram.llModule;
    IRBuilder<> *builder = aBlock.builder;

    // Returns [NSMutableString stringWithUTF8String:_value]
    Value *klass    = mod->getOrInsertGlobal("OBJC_CLASS_$_NSMutableString", aProgram.llInt8Ty);
    Value *selector = builder->CreateLoad(mod->getOrInsertGlobal("TQStringWithUTF8StringSel", aProgram.llInt8PtrTy));

    Value *strValue = [aProgram getGlobalStringPtr:_value inBlock:aBlock];
    strValue = builder->CreateCall3(aProgram.objc_msgSend, klass, selector, strValue);

    // If there are embedded values we must create a string using strValue as its format
    if([_embeddedValues count] > 0) {
        Value *formatSelector = builder->CreateLoad(mod->getOrInsertGlobal("TQStringWithFormatSel", aProgram.llInt8PtrTy));
        std::vector<Value*> args;
        args.push_back(klass);
        args.push_back(formatSelector);
        args.push_back(strValue);
        for(TQNode *value in _embeddedValues) {
            args.push_back([value generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr]);
        }
        strValue = builder->CreateCall(aProgram.objc_msgSend, args);
    }
    return strValue;
}
@end
