#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeNumber : TQNode
@property(readwrite, retain) NSNumber *value;
+ (TQNodeNumber *)nodeWithDouble:(double)aDouble;
- (id)initWithDouble:(double)aDouble;
@end
