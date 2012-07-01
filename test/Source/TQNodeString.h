#import "TQNode.h"

@interface TQNodeString : TQNode
@property(readwrite, retain) NSString *value;
+ (TQNodeString *)nodeWithCString:(const char *)aStr;
- (id)initWithCString:(const char *)aStr;
@end
