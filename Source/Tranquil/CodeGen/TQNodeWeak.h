#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeWeak : TQNode
@property(readwrite, retain) TQNode *value;

+ (TQNodeWeak *)node;
+ (TQNodeWeak *)nodeWithValue:(TQNode *)aValue;
@end
