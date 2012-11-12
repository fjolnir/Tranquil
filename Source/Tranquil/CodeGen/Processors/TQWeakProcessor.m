#import "TQWeakProcessor.h"
#import "../TQNodeWeak.h"
#import "../TQNodeBlock.h"
#import "../TQNodeMethod.h"
#import "../TQNodeOperator.h"
#import "../TQNodeVariable.h"
#import <sys/param.h>

@implementation TQWeakProcessor
+ (void)load
{
    if(self != [TQWeakProcessor class])
        return;
    [TQProcessor registerProcessor:self];
}

+ (TQNode *)processNode:(TQNode *)aNode withTrace:(OFArray *)aTrace
{
    if(![aNode isKindOfClass:[TQNodeWeak class]])
        return aNode;
    TQNodeWeak *weak = (TQNodeWeak *)aNode;
    // Currently we only support heaving direct variable references
    if(![weak.value isKindOfClass:[TQNodeVariable class]])
        return aNode;
    TQNodeVariable *referencedVar = (TQNodeVariable *)weak.value;

    TQNodeBlock *containingBlock = nil;
    TQNodeBlock *parentBlock     = nil;

    for(int i = [aTrace count] - 1; i <= 0; --i) {
        TQNode *node = [aTrace objectAtIndex:i];
        // The containing block, must be a TQNodeBlock, however the parent of that block could be any block subtype.
        if(!containingBlock && ([node isMemberOfClass:[TQNodeBlock class]] || [node isMemberOfClass:[TQNodeMethod class]] || [node isMemberOfClass:[TQNodeRootBlock class]]))
            containingBlock = (TQNodeBlock *)node;
        // The parent block is the first one to hold a strong reference to the variable
        else if(!parentBlock && [node isKindOfClass:[TQNodeBlock class]] && [node referencesNode:referencedVar]) {
            parentBlock = (TQNodeBlock *)node;
            break;
        }
    }
    // If there's no parent, then there's nowhere to heave the reference to
    if(!parentBlock)
        return aNode;
    // If the containing block already holds a strong reference to the variable, then there's no point in moving the referene
    if([containingBlock referencesNode:referencedVar])
        return aNode;

    // If there are no strong references to the variable in the containing block then
    // we create an anonymous variable in the parent block, move the weak to it, and then replace the weak in
    // the containing block of the weak, with a reference to said variable
    TQNode *lastRefInTrace         = [aTrace objectAtIndex:[aTrace indexOfObject:parentBlock]+1];
    TQNode *possibleExistingAssign = [parentBlock.statements objectAtIndex:MAX(0, [parentBlock.statements indexOfObject:lastRefInTrace] - 1)];
    TQNodeVariable *var = [TQNodeVariable tempVar];

    TQNodeOperator *assignment = [TQNodeOperator nodeWithType:kTQOperatorAssign
                                                         left:var
                                                        right:weak];
    if([assignment isEqual:possibleExistingAssign])
        assignment = (TQNodeOperator *)possibleExistingAssign;
    else
        [parentBlock insertChildNode:assignment before:lastRefInTrace];
    [[aTrace lastObject] replaceChildNodesIdenticalTo:weak with:var];
    return aNode;
}
@end
