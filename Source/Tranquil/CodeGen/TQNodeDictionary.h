#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeDictionary : TQNode
@property(readwrite, retain) OFMutableDictionary *items;

+ (TQNodeDictionary *)node;
@end

