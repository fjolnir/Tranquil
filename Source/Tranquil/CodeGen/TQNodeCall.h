#import <Tranquil/CodeGen/TQNode.h>

// A call to a block (block: argument.)
@interface TQNodeCall : TQNode
@property(readwrite, retain) TQNode *callee;
@property(readwrite, retain) NSMutableArray *arguments;
+ (TQNodeCall *)nodeWithCallee:(TQNode *)aCallee;
- (id)initWithCallee:(TQNode *)aCallee;
@end
