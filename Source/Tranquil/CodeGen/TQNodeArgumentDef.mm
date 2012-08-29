#import "TQNodeArgumentDef.h"
#import "../Shared/TQDebug.h"

using namespace llvm;

@implementation TQNodeArgumentDef
@synthesize name=_name, defaultArgument=_defaultArgument;

+ (TQNodeArgumentDef *)nodeWithName:(NSString *)aName
{
    TQNodeArgumentDef *ret = [self new];
    ret.name = aName;

    return [ret autorelease];
}

- (NSUInteger)hash
{
    return [_name hash];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<argdef@ %@>", _name];
}

- (void)dealloc
{
    [_name release];
    [super dealloc];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    TQAssert(NO, @"Argument definitions do not generate code");
    return NULL;
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    TQNode *ref = nil;
    if([aNode isEqual:self])
        return aNode;
    else if((ref = [_defaultArgument referencesNode:aNode]))
        return ref;
    return nil;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    if(_defaultArgument)
        aBlock(_defaultArgument);
}

@end

@implementation TQNodeMethodArgumentDef
@synthesize selectorPart=_selectorPart;

+ (TQNodeMethodArgumentDef *)nodeWithName:(NSString *)aName selectorPart:(NSString *)aSelectorPart
{
    TQNodeMethodArgumentDef *ret = (TQNodeMethodArgumentDef*)[super nodeWithName:aName];;
    ret.selectorPart = aSelectorPart;

    return ret;
}

- (void)dealloc
{
    [_selectorPart release];
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<argdef@ %@: %@>", _selectorPart, _name];
}

@end
