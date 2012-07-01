#import "TQNode.h"

@interface TQNodeDictionary : TQNode
@property(readwrite, copy) NSMapTable *items;

+ (TQNodeDictionary *)node;
@end

