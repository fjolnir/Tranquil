#ifndef TQ_NO_BIGNUM
#import "TQBigNumber.h"
#import "TQNumber.h"

#define DBL_OP(out, op, dbl) {\
    mpf_t tmp; \
    mpf_init_set_d(tmp, (dbl)); \
    op((out), _value, tmp); \
    mpf_clear(tmp); \
}

#define TQBigNumberPrecision 8192

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
    if(!_value[0]._mp_d)
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

- (NSMutableString *)toString
{
    mp_exp_t exp;
    char *str = mpf_get_str(NULL, &exp, 10, 0, _value);
    long len = strlen(str);
    NSMutableString *ret = [NSMutableString stringWithUTF8String:len == 0 ? "0" : str];
    if(len < exp) {
        for(int i = exp; i > len; --i)
            [ret appendString:@"0"];
    } else if(len > exp)
        [ret insertString:@"." atIndex:MAX(0, exp)];
    free(str);
    return ret;
}

- (NSString *)description
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

- (NSComparisonResult)compare:(id)b
{
    int result;
    if(object_getClass(self) != object_getClass(b))
        result = mpf_cmp_d(_value, [b doubleValue]);
    else
        result = mpf_cmp(_value, ((TQBigNumber *)b)->_value);
    return (NSComparisonResult)MAX(-1, MIN(result, 1));
}

- (TQBigNumber *)add:(id)b
{
    TQBigNumber *ret = [[self class] new];
    if(object_getClass(self) != object_getClass(b))
        DBL_OP(ret->_value, mpf_add, [b doubleValue])
    else
        mpf_add(ret->_value, _value, ((TQBigNumber *)b)->_value);
    return [ret autorelease];
}
- (TQBigNumber *)subtract:(id)b
{
    TQBigNumber *ret = [[self class] new];
    if(object_getClass(self) != object_getClass(b))
        DBL_OP(ret->_value, mpf_sub, [b doubleValue])
    else
        mpf_sub(ret->_value, _value, ((TQBigNumber *)b)->_value);
    return [ret autorelease];
}

- (TQBigNumber *)negate
{
    TQBigNumber *ret = [[self class] new];
    mpf_neg(ret->_value, _value);
    return [ret autorelease];
}

- (TQBigNumber *)abs
{
    TQBigNumber *ret = [[self class] new];
    mpf_abs(ret->_value, _value);
    return [ret autorelease];
}
- (TQBigNumber *)ceil
{
    TQBigNumber *ret = [[self class] new];
    mpf_ceil(ret->_value, _value);
    return [ret autorelease];
}
- (TQBigNumber *)floor
{
    TQBigNumber *ret = [[self class] new];
    mpf_floor(ret->_value, _value);
    return [ret autorelease];
}

- (TQBigNumber *)multiply:(id)b
{
    TQBigNumber *ret = [[self class] new];
    if(object_getClass(self) != object_getClass(b))
        DBL_OP(ret->_value, mpf_mul, [b doubleValue])
    else
        mpf_mul(ret->_value, _value, ((TQBigNumber *)b)->_value);
    return [ret autorelease];
}

- (TQBigNumber *)divide:(id)b
{
    TQBigNumber *ret = [[self class] new];
    if(object_getClass(self) != object_getClass(b)) 
        DBL_OP(ret->_value, mpf_div, [b doubleValue])
    else
        mpf_div(ret->_value, _value, ((TQBigNumber *)b)->_value);
    return [ret autorelease];
}

- (TQBigNumber *)pow:(id)b
{
    TQBigNumber *ret = [[self class] new];
    NSLog(@"%@^%@", self, b);
    if(object_getClass(self) != object_getClass(b))
        mpf_pow_ui(ret->_value, _value, [b unsignedLongValue]);
    else
        mpf_pow_ui(ret->_value, _value, mpf_get_ui(((TQBigNumber *)b)->_value));
    return [ret autorelease];
}
- (TQBigNumber *)sqrt
{
    TQBigNumber *ret = [[self class] new];
    mpf_sqrt(ret->_value, _value);
    return [ret autorelease];
}

#pragma mark - Batch allocation code
TQ_BATCH_IMPL(TQBigNumber)
- (void)dealloc
{
    mpf_set_d(_value, 0.0);
    TQ_BATCH_DEALLOC
}
@end
#endif
