#ifndef TQ_NO_BIGNUM
#import "TQBigNumber.h"
#import "TQNumber.h"
#import <math.h>
#import <string.h>
#import <sys/param.h>

#define DBL_OP(out, op, dbl) {\
    mpf_t tmp; \
    mpf_init_set_d(tmp, (dbl)); \
    op((out), _value, tmp); \
    mpf_clear(tmp); \
}

@class TQNumber;

#define TQBigNumberPrecision 2048

static const int _TQBigNumberMaxDigits;

@implementation TQBigNumber
@dynamic doubleValue, numberValue;

+ (TQBigNumber *)withDouble:(double)aValue
{
    return [[[[self class] alloc] initWithDouble:aValue] autorelease];
}

+ (TQBigNumber *)withNumber:(TQNumber *)aValue
{
    return [self withDouble:[aValue doubleValue]];
}

- (id)init
{
    if(!(self = [super init]))
        return nil;
    mpf_init2(_value, TQBigNumberPrecision);
    return self;
}

- (id)initWithDouble:(double)aValue
{
    TQAssert(!isnan(aValue) && aValue != INFINITY && aValue != -INFINITY, @"Tried to create a %f BigNumber", aValue);

    if(!(self = [self init]))
        return nil;
    mpf_set_d(_value, aValue);
    return self;
}

#pragma mark - Accessors

- (double)doubleValue
{
    return mpf_get_d(_value);
}

- (TQNumber *)numberValue
{
    return [TQNumber numberWithDouble:mpf_get_d(_value)];
}

- (OFMutableString *)toString
{
    mp_exp_t exp;
    char *str = mpf_get_str(NULL, &exp, 10, 0, _value);
    long len = strlen(str);
    OFMutableString *ret = [OFMutableString stringWithUTF8String:len == 0 ? "0" : str];
    if(len < exp) {
        for(int i = exp; i > len; --i)
            [ret appendString:@"0"];
    } else if(len > exp)
        [ret insertString:@"." atIndex:MAX(0, exp)];
    free(str);
    return ret;
}

- (OFString *)description
{
    return [self toString];
}

#pragma mark - Operators

- (BOOL)isEqual:(id)b
{
    int result;
    if(object_getClass(self) != object_getClass(b))
        result = mpf_cmp_d(_value, [b doubleValue]);
    else
        result = mpf_cmp(_value, ((TQBigNumber *)b)->_value);
    return result == 0;
}

- (of_comparison_result_t)compare:(id)b
{
    int result;
    if(object_getClass(self) != object_getClass(b))
        result = mpf_cmp_d(_value, [b doubleValue]);
    else
        result = mpf_cmp(_value, ((TQBigNumber *)b)->_value);
    return (of_comparison_result_t)MAX(-1, MIN(result, 1));
}

- (TQBigNumber *)add:(id)b
{
    TQBigNumber *ret = [[[self class] alloc] init];
    if(object_getClass(self) != object_getClass(b))
        DBL_OP(ret->_value, mpf_add, [b doubleValue])
    else
        mpf_add(ret->_value, _value, ((TQBigNumber *)b)->_value);
    return [ret autorelease];
}
- (TQBigNumber *)subtract:(id)b
{
    TQBigNumber *ret = [[[self class] alloc] init];
    if(object_getClass(self) != object_getClass(b))
        DBL_OP(ret->_value, mpf_sub, [b doubleValue])
    else
        mpf_sub(ret->_value, _value, ((TQBigNumber *)b)->_value);
    return [ret autorelease];
}

- (TQBigNumber *)negate
{
    TQBigNumber *ret = [[[self class] alloc] init];
    mpf_neg(ret->_value, _value);
    return [ret autorelease];
}

- (TQBigNumber *)abs
{
    TQBigNumber *ret = [[[self class] alloc] init];
    mpf_abs(ret->_value, _value);
    return [ret autorelease];
}
- (TQBigNumber *)ceil
{
    TQBigNumber *ret = [[[self class] alloc] init];
    mpf_ceil(ret->_value, _value);
    return [ret autorelease];
}
- (TQBigNumber *)floor
{
    TQBigNumber *ret = [[[self class] alloc] init];
    mpf_floor(ret->_value, _value);
    return [ret autorelease];
}

- (TQBigNumber *)multiply:(id)b
{
    TQBigNumber *ret = [[[self class] alloc] init];
    if(object_getClass(self) != object_getClass(b))
        DBL_OP(ret->_value, mpf_mul, [b doubleValue])
    else
        mpf_mul(ret->_value, _value, ((TQBigNumber *)b)->_value);
    return [ret autorelease];
}

- (TQBigNumber *)divide:(id)b
{
    TQBigNumber *ret = [[[self class] alloc] init];
    if(object_getClass(self) != object_getClass(b)) 
        DBL_OP(ret->_value, mpf_div, [b doubleValue])
    else
        mpf_div(ret->_value, _value, ((TQBigNumber *)b)->_value);
    return [ret autorelease];
}

- (TQBigNumber *)pow:(id)b
{
    TQBigNumber *ret = [[[self class] alloc] init];
    if(object_getClass(self) != object_getClass(b))
        mpf_pow_ui(ret->_value, _value, [b unsignedLongValue]);
    else
        mpf_pow_ui(ret->_value, _value, mpf_get_ui(((TQBigNumber *)b)->_value));
    return [ret autorelease];
}
- (TQBigNumber *)sqrt
{
    TQBigNumber *ret = [[[self class] alloc] init];
    mpf_sqrt(ret->_value, _value);
    return [ret autorelease];
}
@end
#endif
