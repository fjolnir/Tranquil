#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeNumber : TQNode
@property(readwrite, retain) OFNumber *value;
+ (TQNodeNumber *)nodeWithDouble:(double)aDouble;
- (id)initWithDouble:(double)aDouble;
@end
