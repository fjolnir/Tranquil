#import "TQNodeWeak.h"
#import "../TQProgram.h"

using namespace llvm;

@implementation TQNodeWeak
@synthesize value=_value;

+ (TQNodeWeak *)node
{
    return (TQNodeWeak *)[super node];
}
+ (TQNodeWeak *)nodeWithValue:(TQNode *)aValue
{
    TQNodeWeak *ret = [self node];
    ret->_value = [aValue retain];
    return ret;
}
- (void)dealloc
{
    [_value release];
    [super dealloc];
}

- (id)referencesNode:(TQNode *)aNode
{
    if([aNode isEqual:self])
        return self;
    return nil;
    //return [_value referencesNode:aNode];
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    aBlock(_value);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<weak: ~%@>", _value];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                 error:(NSError **)aoError
{
    Module *mod     = aProgram.llModule;
    Value *selector = aBlock.builder->CreateLoad(mod->getOrInsertGlobal("TQWeakSel", aProgram.llInt8PtrTy), "weakSel");
    Value *klass    = mod->getOrInsertGlobal("OBJC_CLASS_$_TQWeak", aProgram.llInt8Ty);


    return aBlock.builder->CreateCall3(aProgram.objc_msgSend, klass, selector, [_value generateCodeInProgram:aProgram block:aBlock error:aoError]);
}
@end
