#import "TQNodeArgumentDef.h"
#import "../TQDebug.h"

using namespace llvm;

@implementation TQNodeArgumentDef
@synthesize name=_name, selectorPart=_selectorPart, defaultArgument=_defaultArgument;

+ (TQNodeArgumentDef *)nodeWithName:(NSString *)aName selectorPart:(NSString *)aIdentifier
{
    return [[[self alloc] initWithName:aName selectorPart:aIdentifier] autorelease];
}

- (id)initWithName:(NSString *)aName selectorPart:(NSString *)aIdentifier
{
    if(!(self = [super init]))
        return nil;

    _name = [aName retain];
    _selectorPart = [aIdentifier retain];

    return self;
}

- (NSUInteger)hash
{
    return [_name hash];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<argdef@ %@: %@>", _selectorPart, _name];
}

- (void)dealloc
{
    [_selectorPart release];
    [_name release];
    [super dealloc];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoError
{
    TQAssert(NO, "Argument definitions do not generate code");
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
@end
