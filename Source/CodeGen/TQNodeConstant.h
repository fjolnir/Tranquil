#import "TQNode.h"
#import "TQNodeIdentifier.h"

@interface TQNodeConstant : TQNodeIdentifier
+ (TQNodeConstant *)nodeWithCString:(const char *)aStr;
@end
