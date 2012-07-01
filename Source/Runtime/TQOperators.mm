#import "TQOperators.h"

@implementation NSNumber (TQOperators)
- (NSNumber *)add:(NSNumber *)b
{
    return [NSNumber numberWithDouble:self.doubleValue + b.doubleValue];
}
- (NSNumber *)subtract:(NSNumber *)b
{
    return [NSNumber numberWithDouble:self.doubleValue - b.doubleValue];
}
- (NSNumber *)negate
{
    return [NSNumber numberWithDouble:-1.0*self.doubleValue];
}

- (NSNumber *)multiply:(NSNumber *)b
{
    return [NSNumber numberWithDouble:self.doubleValue * b.doubleValue];
}
- (NSNumber *)divide:(NSNumber *)b
{
    return [NSNumber numberWithDouble:self.doubleValue / b.doubleValue];
}
- (id)if:(condBlock)ifBlock else:(condBlock)elseBlock
{
    if([self boolValue])
        return ifBlock();
    else
        return elseBlock();
}
@end
