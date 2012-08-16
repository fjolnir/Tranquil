#import "NSNumber+TQOperators.h"
#import "TQRuntime.h"

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

- (NSNumber *)ceil
{
    return [NSNumber numberWithDouble:ceil([self doubleValue])];
}
- (NSNumber *)floor
{
    return [NSNumber numberWithDouble:floor([self doubleValue])];
}

- (NSNumber *)modulo:(id)b
{
    return [NSNumber numberWithDouble:fmod([self doubleValue], [b doubleValue])];
}
- (NSNumber *)pow:(id)b
{
    return [NSNumber numberWithDouble:pow([self doubleValue], [b doubleValue] )];
}

- (NSNumber *)bitAnd:(id)b
{
    return [NSNumber numberWithLong:[self longValue] & [b longValue]];
}

- (NSNumber *)bitOr:(id)b
{
    return [NSNumber numberWithLong:[self longValue] | [b longValue]];
}

- (NSNumber *)xor:(id)b
{
    return [NSNumber numberWithLong:[self longValue] ^ [b longValue]];
}

- (NSNumber *)lshift:(id)b
{
    return [NSNumber numberWithLong:[self longValue] << [b longValue]];
}

- (NSNumber *)rshift:(id)b
{
    return [NSNumber numberWithLong:[self longValue] >> [b longValue]];
}



- (id)isGreater:(id)b
{
    return [self doubleValue] > [b doubleValue]  ? TQValid : nil;
}

- (id)isLesser:(id)b
{
    return [self doubleValue] < [b doubleValue]  ? TQValid : nil;
}

- (id)isGreaterOrEqual:(id)b
{
    return [self doubleValue] >= [b doubleValue]  ? TQValid : nil;
}

- (id)isLesserOrEqual:(id)b
{
    return [self doubleValue] <= [b doubleValue]  ? TQValid : nil;
}
@end
