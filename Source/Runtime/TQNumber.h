#import "TQPooledObject.h"

typedef id (^condBlock)();

@interface TQNumber : TQPooledObject
@property(readwrite, assign) double doubleValue;

+ (TQNumber *)numberWithDouble:(double)aValue;

- (TQNumber *)add:(TQNumber *)b;
- (TQNumber *)subtract:(TQNumber *)b;
- (TQNumber *)negate;
- (TQNumber *)multiply:(TQNumber *)b;
- (TQNumber *)divide:(TQNumber *)b;

- (id)if:(condBlock)ifBlock else:(condBlock)elseBlock;
@end
