#import "TQNode.h"

@interface TQNodeArray : TQNode
@property(readwrite, copy) NSMutableArray *items;

+ (TQNodeArray *)node;
@end
