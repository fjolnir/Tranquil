#import "TQNode.h"

@interface TQNodeVariable : TQNode
@property(readwrite, retain) NSString *name;
+ (TQNodeVariable *)nodeWithName:(NSString *)aName;
- (id)initWithName:(NSString *)aName;
@end
