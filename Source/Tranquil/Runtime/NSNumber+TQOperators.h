#import <Foundation/Foundation.h>

@interface NSNumber (TQOperators)
- (NSNumber *)add:(id)b;
- (NSNumber *)subtract:(id)b;
- (NSNumber *)negate;

- (NSNumber *)multiply:(id)b;
- (NSNumber *)divide:(id)b;

- (NSNumber *)ceil;
- (NSNumber *)floor;

- (NSNumber *)modulo:(id)b;
- (NSNumber *)pow:(id)b;

- (NSNumber *)bitAnd:(id)b;
- (NSNumber *)bitOr:(id)b;
- (NSNumber *)xor:(id)b;
- (NSNumber *)lshift:(id)b;
- (NSNumber *)rshift:(id)b;

- (id)isGreater:(id)b;
- (id)isLesser:(id)b;
- (id)isGreaterOrEqual:(id)b;
- (id)isLesserOrEqual:(id)b;
@end
