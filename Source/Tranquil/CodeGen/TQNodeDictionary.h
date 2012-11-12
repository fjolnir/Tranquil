#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeDictionary : TQNode
@property(readwrite, copy) OFMutableDictionary *items;

+ (TQNodeDictionary *)node;
@end

