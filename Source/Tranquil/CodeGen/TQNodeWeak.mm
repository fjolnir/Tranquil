#import "TQNodeWeak.h"
#import "TQNode+Private.h"
#import "TQNodeBlock.h"
#import "TQProgram.h"

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

- (BOOL)isEqual:(id)b
{
    if(![b isMemberOfClass:[self class]])
        return NO;
    return [_value isEqual:[b value]];
}

- (id)referencesNode:(TQNode *)aNode
{
    if([aNode isEqual:self])
        return self;
    return nil;
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
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    Module *mod     = aProgram.llModule;
    Value *selector = [aProgram getSelector:@"with:" inBlock:aBlock root:aRoot];
    Value *klass    = mod->getOrInsertGlobal("OBJC_CLASS_$_TQWeak", aProgram.llInt8Ty);


    Value *ret = aBlock.builder->CreateCall3(aProgram.objc_msgSend, klass, selector, [_value generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr]);
    [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];
    return ret;
}
@end
