#import <Tranquil/CodeGen/TQNode.h>
#import "TQNodeString.h"

@interface TQNodeConstant : TQNodeString
+ (TQNodeConstant *)nodeWithString:(OFMutableString *)aStr;
@end
