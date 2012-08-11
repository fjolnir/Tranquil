#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeWeak : TQNode {
    TQNode *_value;
}
+ (TQNodeWeak *)node;
+ (TQNodeWeak *)nodeWithValue:(TQNode *)aValue;
@end
