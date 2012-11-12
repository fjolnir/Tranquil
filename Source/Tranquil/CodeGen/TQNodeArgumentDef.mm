#import "TQNodeArgumentDef.h"
#import "../Shared/TQDebug.h"

using namespace llvm;

@implementation TQNodeArgumentDef
@synthesize name=_name, defaultArgument=_defaultArgument, unretained=_unretained;

+ (TQNodeArgumentDef *)nodeWithName:(OFString *)aName
{
    TQNodeArgumentDef *ret = [self new];
    ret.name = aName;

    return [ret autorelease];
}

- (uint32_t)hash
{
    return [_name hash];
}

- (OFString *)description
{
    return [OFString stringWithFormat:@"<argdef@ %@>", _name];
}

- (void)dealloc
{
    [_name release];
    [super dealloc];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(TQError **)aoErr
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

+ (TQNodeMethodArgumentDef *)nodeWithName:(OFString *)aName selectorPart:(OFString *)aSelectorPart
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

- (OFString *)description
{
    return [OFString stringWithFormat:@"<argdef@ %@: %@>", _selectorPart, _name];
}

@end
