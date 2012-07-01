#import "TQNode.h"
#import "TQNodeString.h"

@interface TQNodeIdentifier : TQNodeString
+ (TQNodeIdentifier *)nodeWithCString:(const char *)aStr;
@end
