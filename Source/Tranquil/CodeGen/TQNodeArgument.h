#import "TQNode.h"

// An argument to block (name: arg)
@interface TQNodeArgument : TQNode
@property(readwrite, retain) OFString *selectorPart;  // The argument identifier, that is, the portion before ':'
@property(readwrite, retain) TQNode *passedNode;    // The node after ':'

+ (TQNodeArgument *)nodeWithPassedNode:(TQNode *)aNode selectorPart:(OFString *)aIdentifier;
- (id)initWithPassedNode:(TQNode *)aNode selectorPart:(OFString *)aIdentifier;
@end
