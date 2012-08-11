#import <Tranquil/CodeGen/TQNodeArgument.h>

using namespace llvm;

@implementation TQNodeArgument
@synthesize passedNode=_passedNode, selectorPart=_selectorPart;

+ (TQNodeArgument *)nodeWithPassedNode:(TQNode *)aNode selectorPart:(NSString *)aIdentifier
{
    return [[[self alloc] initWithPassedNode:aNode selectorPart:aIdentifier] autorelease];
}

- (id)initWithPassedNode:(TQNode *)aNode selectorPart:(NSString *)aIdentifier
{
    if(!(self = [super init]))
        return nil;

    _passedNode = [aNode retain];
    _selectorPart = [aIdentifier retain];

    return self;
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    TQNode *ref = nil;
    if([aNode isEqual:self])
        ref = self;
    else if((ref = [_passedNode referencesNode:aNode]))
        return ref;
    return ref;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    aBlock(_passedNode);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<arg@ %@: %@>", _selectorPart, _passedNode];
}

- (void)dealloc
{
    [_selectorPart release];
    [_passedNode release];
    [super dealloc];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoError
{
    return [_passedNode generateCodeInProgram:aProgram block:aBlock error:aoError];
}
@end
