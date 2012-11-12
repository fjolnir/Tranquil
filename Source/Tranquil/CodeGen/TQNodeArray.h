#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeArray : TQNode
@property(readwrite, copy) OFMutableArray *items;

+ (TQNodeArray *)node;
@end
