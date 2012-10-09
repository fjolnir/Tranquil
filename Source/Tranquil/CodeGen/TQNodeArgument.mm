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

- (BOOL)isEqual:(id)aOther
{
    if(![aOther isMemberOfClass:[self class]])
        return NO;
    return (_passedNode == [aOther passedNode] || [_passedNode isEqual:[aOther passedNode]]) && [_selectorPart isEqual:[aOther selectorPart]];
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

- (BOOL)replaceChildNodesIdenticalTo:(TQNode *)aNodeToReplace with:(TQNode *)aNodeToInsert
{
    if(_passedNode == aNodeToReplace) {
        self.passedNode = aNodeToReplace;
        return YES;
    }
    return [_passedNode replaceChildNodesIdenticalTo:aNodeToReplace with:aNodeToInsert];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<arg@ %@: %@>", _selectorPart, _passedNode];
}
- (NSString *)toString
{
    return [NSString stringWithFormat:@"%@: %@", _selectorPart, [_passedNode toString]];
}

- (void)dealloc
{
    [_selectorPart release];
    [_passedNode release];
    [super dealloc];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    return [_passedNode generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
}
@end
