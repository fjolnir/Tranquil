#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeCollect : TQNode
@property(readwrite, retain) NSMutableArray *statements;

+ (TQNodeCollect *)node;
@end
