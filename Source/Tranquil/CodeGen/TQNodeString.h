#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeString : TQNode
@property(readwrite, retain) NSString *value;
+ (TQNodeString *)nodeWithString:(NSString *)aStr;
@end
