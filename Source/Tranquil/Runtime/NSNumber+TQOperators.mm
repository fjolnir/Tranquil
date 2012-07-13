#import "NSNumber+TQOperators.h"

@implementation NSNumber (TQOperators)
- (NSNumber *)add:(id)b
{
    return [NSNumber numberWithDouble:self.doubleValue + [b doubleValue]];
}
- (NSNumber *)subtract:(id)b
{
    return [NSNumber numberWithDouble:self.doubleValue - [b doubleValue]];
}
- (NSNumber *)negate
{
    return [NSNumber numberWithDouble:-1.0*self.doubleValue];
}

- (NSNumber *)multiply:(id)b
{
    return [NSNumber numberWithDouble:self.doubleValue * [b doubleValue]];
}
- (NSNumber *)divide:(id)b
{
    return [NSNumber numberWithDouble:self.doubleValue / [b doubleValue]];
}
@end
