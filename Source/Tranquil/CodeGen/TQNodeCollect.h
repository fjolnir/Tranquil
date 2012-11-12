#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeCollect : TQNode
@property(readwrite, retain) OFMutableArray *statements;

+ (TQNodeCollect *)node;
@end
