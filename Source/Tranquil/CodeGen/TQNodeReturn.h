#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeReturn : TQNode
@property(readwrite, retain) TQNode *value;
@property(readwrite, assign) int depth; // How many levels up the lexical hierarchy to return?
+ (TQNodeReturn *)nodeWithValue:(TQNode *)aValue;
- (id)initWithValue:(TQNode *)aValue;
@end
