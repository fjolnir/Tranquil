#import "TQInitInsertProcessor.h"
#import "../TQNodeOperator.h"
#import "../TQNodeMethod.h"
#import "../TQNodeMessage.h"
#import "../TQNodeVariable.h"
#import "../TQNodeArgument.h"
#import "../TQNodeNil.h"
#import "../TQNodeConditionalBlock.h"

@implementation TQInitInsertProcessor
+ (void)load
{
    if(self != [TQInitInsertProcessor class])
        return;
    [TQProcessor registerProcessor:self];
}

+ (TQNode *)processNode:(TQNode *)aNode withTrace:(NSArray *)aTrace
{
    if(![aNode isKindOfClass:[TQNodeMethod class]])
        return aNode;
    TQNodeMethod *method = (TQNodeMethod *)aNode;

    if(method.type == kTQInstanceMethod && [[method selector] isEqualToString:@"init"]) {
        TQNodeMessage *superInit = [TQNodeMessage nodeWithReceiver:[TQNodeSuper node]];
        [superInit.arguments addObject:[TQNodeArgument nodeWithPassedNode:nil selectorPart:@"init"]];
        if(![method referencesNode:superInit]) {
            TQNodeOperator *selfAsgn = [TQNodeOperator nodeWithType:kTQOperatorAssign
                                                               left:[TQNodeSelf node]
                                                              right:superInit];
            TQNodeUnlessBlock *nilTest = [TQNodeUnlessBlock nodeWithCondition:selfAsgn
                                                                 ifStatements:[NSMutableArray arrayWithObject:[TQNodeReturn node]]
                                                               elseStatements:nil];

            [method.statements insertObject:nilTest atIndex:0];
        }
    }

    return aNode;
}
@end
