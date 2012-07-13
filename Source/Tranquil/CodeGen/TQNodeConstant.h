#import <Tranquil/CodeGen/TQNode.h>
#import "TQNodeString.h"

@interface TQNodeConstant : TQNodeString
+ (TQNodeConstant *)nodeWithString:(NSMutableString *)aStr;
@end
