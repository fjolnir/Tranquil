#import "TQPooledObject.h"

typedef id (^condBlock)();

@interface TQNumber : TQPooledObject
@property(readonly) double doubleValue;

+ (TQNumber *)numberWithDouble:(double)aValue;

- (TQNumber *)add:(TQNumber *)b;
- (TQNumber *)subtract:(TQNumber *)b;
- (TQNumber *)negate;
- (TQNumber *)multiply:(TQNumber *)b;
- (TQNumber *)divideBy:(TQNumber *)b;

- (TQNumber *)addDouble:(double)b;
- (TQNumber *)subtractDouble:(double)b;
- (TQNumber *)multiplyDouble:(double)b;
- (TQNumber *)divideByDouble:(double)b;

- (id)if:(condBlock)ifBlock else:(condBlock)elseBlock;
@end
