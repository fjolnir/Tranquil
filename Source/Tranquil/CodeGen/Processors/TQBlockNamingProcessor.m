#import "TQBlockNamingProcessor.h"
#import "../TQNodeOperator.h"
#import "../TQNodeMethod.h"
#import "../TQNodeMessage.h"
#import "../TQNodeVariable.h"
#import "../TQNodeArgument.h"
#import "../TQNodeNil.h"
#import "../TQNodeConditionalBlock.h"

@implementation TQBlockNamingProcessor
+ (void)load
{
    if(self != [TQBlockNamingProcessor class])
        return;
    [TQProcessor registerProcessor:self];
}

+ (TQNode *)processNode:(TQNode *)aNode withTrace:(NSArray *)aTrace
{
    if(![aNode isKindOfClass:[TQNodeBlock class]] || [aNode isKindOfClass:[TQNodeMethod class]])
        return aNode;
    TQNodeBlock *blk = (TQNodeBlock *)aNode;
    TQNodeOperator *parent = [aTrace lastObject];
    if(![parent isKindOfClass:[TQNodeOperator class]])
        return aNode;
    if(parent.type != kTQOperatorAssign || ![parent.left isKindOfClass:[TQNodeVariable class]])
        return aNode;
    TQNodeVariable *var = (TQNodeVariable *)parent.left;
    blk.invokeName = [NSString stringWithFormat:@"__tq_%@_invoke", var.name];
    return aNode;
}
@end
