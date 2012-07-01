#import "TQNode.h"

// An argument to block (name: arg)
@interface TQNodeArgument : TQNode
@property(readwrite, retain) NSString *identifier;  // The argument identifier, that is, the portion before ':'
@property(readwrite, retain) TQNode *passedNode;    // The node after ':'

+ (TQNodeArgument *)nodeWithPassedNode:(TQNode *)aNode identifier:(NSString *)aIdentifier;
- (id)initWithPassedNode:(TQNode *)aNode identifier:(NSString *)aIdentifier;
@end
