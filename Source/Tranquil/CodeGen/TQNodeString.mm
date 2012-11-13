#import "TQNodeString.h"
#import "TQNode+Private.h"
#import "TQNodeBlock.h"
#import "TQProgram.h"

using namespace llvm;

@implementation TQNodeString
@synthesize value=_value;

+ (TQNodeString *)nodeWithString:(OFMutableString *)aStr
{
    TQNodeString *node = [self new];
    node.value = aStr;
    return [node autorelease];
}

- (id)init
{
    if(!(self = [super init]))
        return nil;
    _embeddedValues = [OFMutableArray new];
    return self;
}

- (void)dealloc
{
    [_value release];
    [_embeddedValues release];
    [super dealloc];
}

- (OFString *)description
{
    return [OFString stringWithFormat:@"<str@ \"%@\">", _value];
}
- (OFString *)toString
{
    return _value;
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

- (void)append:(OFString *)aStr
{
    [_value appendString:aStr];
}

- (BOOL)replaceChildNodesIdenticalTo:(TQNode *)aNodeToReplace with:(TQNode *)aNodeToInsert
{
    unsigned long idx = [_embeddedValues indexOfObject:aNodeToReplace];
    if(idx == OF_NOT_FOUND)
        return NO;
    [_embeddedValues replaceObjectAtIndex:idx withObject:aNodeToInsert];
    return YES;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(TQError **)aoErr
{
    Module *mod = aProgram.llModule;

    // Returns [OFMutableString stringWithUTF8String:_value]
#ifdef __APPLE__
    Value *klass    = mod->getOrInsertGlobal("OBJC_CLASS_$_OFMutableString", aProgram.llInt8Ty);
#else
    Value *klass    = mod->getOrInsertGlobal("OBJC_CLASS_$_OFMutableString", aProgram.llInt8Ty);
#endif
    Value *selector = aBlock.builder->CreateLoad(mod->getOrInsertGlobal("TQStringWithUTF8StringSel", aProgram.llInt8PtrTy));

    Value *strValue = [aProgram getGlobalStringPtr:_value inBlock:aBlock];
    strValue = aBlock.builder->CreateCall3(aProgram.objc_msgSend, klass, selector, strValue);

    // If there are embedded values we must create a string using strValue as its format
    if([_embeddedValues count] > 0) {
        Value *formatSelector = aBlock.builder->CreateLoad(mod->getOrInsertGlobal("TQStringWithFormatSel", aProgram.llInt8PtrTy));
        std::vector<Value*> args;
        args.push_back(klass);
        args.push_back(formatSelector);
        args.push_back(strValue);
        for(TQNode *value in _embeddedValues) {
            args.push_back([value generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr]);
        }
        strValue = aBlock.builder->CreateCall(aProgram.objc_msgSend, args);
        [self _attachDebugInformationToInstruction:strValue inProgram:aProgram block:aBlock root:aRoot];
    }
    return strValue;
}
@end

@implementation TQNodeConstString
+ (TQNodeConstString *)nodeWithString:(OFString *)aStr
{
    return (TQNodeConstString *)[super nodeWithString:[[aStr mutableCopy] autorelease]];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(TQError **)aoErr
{
    Module *mod = aProgram.llModule;

    OFString *globalName;
    if(aProgram.useAOTCompilation)
        globalName = [OFString stringWithFormat:@"TQConstNSStr_%ld", [self.value hash]];
    else
        globalName = [OFString stringWithFormat:@"TQConstNSStr_%@", self.value];

    Value *str = mod->getGlobalVariable([globalName UTF8String], true);
    if(!str) {
         Function *rootFunction = aRoot.function;
        IRBuilder<> rootBuilder(&rootFunction->getEntryBlock(), rootFunction->getEntryBlock().begin());

        Value *klass    = mod->getOrInsertGlobal("OBJC_CLASS_$_OFString", aProgram.llInt8Ty);
        Value *selector = rootBuilder.CreateLoad(mod->getOrInsertGlobal("TQStringWithUTF8StringSel", aProgram.llInt8PtrTy));

        Value *result = rootBuilder.CreateCall3(aProgram.objc_msgSend, klass, selector, [aProgram getGlobalStringPtr:self.value withBuilder:&rootBuilder]);
        result = rootBuilder.CreateCall(aProgram.objc_retain, result);

        str = new GlobalVariable(*mod, aProgram.llInt8PtrTy, false, GlobalVariable::InternalLinkage,
                                 ConstantPointerNull::get(aProgram.llInt8PtrTy), [globalName UTF8String]);

        rootBuilder.CreateStore(result, str);

    }
    return aBlock.builder->CreateLoad(str);
}
@end
