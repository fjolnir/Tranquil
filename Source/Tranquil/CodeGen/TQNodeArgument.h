#import "TQNode.h"

// An argument to block (name: arg)
@interface TQNodeArgument : TQNode
@property(readwrite, retain) NSString *selectorPart;  // The argument identifier, that is, the portion before ':'
@property(readwrite, retain) TQNode *passedNode; // The node after ':'

+ (TQNodeArgument *)nodeWithselectorPart:(NSString *)aIdentifier;
+ (TQNodeArgument *)nodeWithPassedNode:(TQNode *)aNode selectorPart:(NSString *)aIdentifier;
- (id)initWithPassedNode:(TQNode *)aNode selectorPart:(NSString *)aIdentifier;
@end
