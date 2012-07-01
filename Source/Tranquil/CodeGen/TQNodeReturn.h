#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeReturn : TQNode
@property(readwrite, retain) TQNode *value;
+ (TQNodeReturn *)nodeWithValue:(TQNode *)aValue;
- (id)initWithValue:(TQNode *)aValue;
@end
