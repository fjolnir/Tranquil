#import "TQNumber.h"
#import <objc/runtime.h>
#import "TQRuntime.h"
#import "TQRange.h"
#import "TQBigNumber.h"
#import "../../../Build/TQStubs.h"

@interface TQTaggedNumber : TQNumber
@end

#define IS_TAGGED(ptr) ((uintptr_t)(ptr) & 1)

union CoercedValue {
    void *ptr;
    uintptr_t addr;
    float floatValue;
    double doubleValue;
};

// Largest value accurately representable by a tagged pointer
static const double TQTaggedNumberLimit = 1.0f/FLT_EPSILON;
// Largest value accurately representable by an allocated object
static const double TQNumberLimit       = 1.0/DBL_EPSILON;

static id (*numberWithDoubleImp)(id, SEL, double);
static id (*numberWithLongImp)(id, SEL, long);
static id (*allocImp)(id,SEL,NSZone*);
static id (*initImp)(id,SEL,double);
static id (*autoreleaseImp)(id,SEL);

// Hack from libobjc, aLows tail caL optimization for objc_msgSend
extern id _objc_msgSend_hack(id, SEL)      asm("_objc_msgSend");
extern id _objc_msgSend_hack2(id, SEL, id) asm("_objc_msgSend");

// Tagged pointer niceness (Uses floats by truncating the mantissa by 1 byte)
extern void _objc_insert_tagged_isa(unsigned char slotNumber, Class isa);

const unsigned char kTQNumberTagSlot  = 5; // Free slot
const uintptr_t     kTQNumberTag      = (kTQNumberTagSlot << 1) | 1;

static __inline__ BOOL _TQTaggedNumberCanHold(double aValue)
{
#ifdef __LP64__
    union CoercedValue val = { .doubleValue = aValue };
    val.addr &= 0x7fffffffffffffffL; // Unset the sign bit
    return val.doubleValue <= TQTaggedNumberLimit;
#else
    return NO; // TODO: Figure out a way to do tagging on 32bit
#endif
}

static __inline__ BOOL _TQNumberCanHold(double aValue)
{
    union CoercedValue val = { .doubleValue = aValue };
    val.addr &= 0x7fffffffffffffffL; // Unset the sign bit
    return val.doubleValue <= TQNumberLimit;
}

static __inline__ id _TQTaggedNumberCreate(float value)
{
#ifdef __LP64__
    union CoercedValue val = { .floatValue = value };
    val.addr = (val.addr << 4) | kTQNumberTag;
    return val.ptr;
#else
    return nil;
#endif
}

TQNumber *TQNumberCreateTagged(float aValue)
{
    NSCAssert(_TQTaggedNumberCanHold(aValue), @"%f is out of tagged number range!", aValue);
    return _TQTaggedNumberCreate(aValue);
}

static __inline__ float _TQTaggedNumberValue(TQTaggedNumber *ptr)
{
#ifdef __LP64__
    union CoercedValue val = { .ptr = ptr };
    val.addr >>= 4;
    return val.floatValue;
#else
    return 0.0f;
#endif
}

#ifdef __LP64__
    #define _TQNumberValue(num) (IS_TAGGED(num) ? _TQTaggedNumberValue((TQTaggedNumber *)(num)) : ((TQNumber *)(num))->_value)
#else
    #define _TQNumberValue(num) (((TQNumber *)(num))->_value)
#endif

BOOL TQFloatFitsInTaggedNumber(float aValue)
{
    return _TQTaggedNumberCanHold(aValue);
}

@implementation TQNumber
@synthesize value=_value;

+ (void)load
{
    if(self != [TQNumber class]) {
        TQLog(@"Warning: Subclassing TQNumber is a bad idea!");
        // These cannot be overridden
        assert((typeof(allocImp))method_getImplementation(class_getClassMethod(self, @selector(allocWithZone:))) == allocImp);
        assert((typeof(initImp))class_getMethodImplementation(self, @selector(initWithDouble:)) == initImp);
        assert((typeof(autoreleaseImp))class_getMethodImplementation(self, @selector(autorelease)) == autoreleaseImp);
    } else {
#ifdef __LP64__
        // Register our tagged pointer slot
        _objc_insert_tagged_isa(kTQNumberTagSlot, [TQTaggedNumber class]);
#endif
    }
    numberWithDoubleImp = (id (*)(id, SEL, double))method_getImplementation(class_getClassMethod(self, @selector(numberWithDouble:)));
    numberWithLongImp   = (id (*)(id, SEL, long))method_getImplementation(class_getClassMethod(self, @selector(numberWithLong:)));

    allocImp = (typeof(allocImp))method_getImplementation(class_getClassMethod(self, @selector(allocWithZone:)));
    initImp = (typeof(initImp))class_getMethodImplementation(self, @selector(initWithDouble:));
    autoreleaseImp = (typeof(autoreleaseImp))class_getMethodImplementation(self, @selector(autorelease));
}

+ (id)fitsInTaggedPointer:(double)aValue
{
    return _TQTaggedNumberCanHold(aValue) ? TQValid : nil;
}

+ (id)fitsInTaggedPointer:(double)aValue onArch:(TQArchitecture)aArch
{
    // TODO: implement this properly
    switch(aArch) {
        case kTQArchitectureX86_64:
        case kTQArchitectureHost:
            return [self fitsInTaggedPointer:aValue];
        default:
            return NO;
    }
}

+ (TQNumber *)numberWithBool:(BOOL)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);
    TQNumber *ret = initImp(allocImp([TQNumber class], @selector(allocWithZone:), nil), @selector(initWithBool:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithChar:(char)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);
    TQNumber *ret = initImp(allocImp([TQNumber class], @selector(allocWithZone:), nil), @selector(initWithChar:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithShort:(short)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);
    TQNumber *ret = initImp(allocImp([TQNumber class], @selector(allocWithZone:), nil), @selector(initWithShort:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithInt:(int)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);

    TQNumber *ret = initImp(allocImp([TQNumber class], @selector(allocWithZone:), nil), @selector(initWithInt:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithLong:(long)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);

    TQNumber *ret = initImp(allocImp([TQNumber class], @selector(allocWithZone:), nil), @selector(initWithLong:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithLongLong:(long long)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);

    TQNumber *ret = initImp(allocImp([TQNumber class], @selector(allocWithZone:), nil), @selector(initWithLongLong:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithFloat:(float)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);

    TQNumber *ret = initImp(allocImp([TQNumber class], @selector(allocWithZone:), nil), @selector(initWithFloat:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithDouble:(double)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);

    TQNumber *ret = initImp(allocImp([TQNumber class], @selector(allocWithZone:), nil), @selector(initWithDouble:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithInteger:(NSInteger)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);

    TQNumber *ret = initImp(allocImp([TQNumber class], @selector(allocWithZone:), nil), @selector(initWithInteger:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}

+ (TQNumber *)numberWithUnsignedChar:(unsigned char)aValue
{
    return _TQTaggedNumberCreate(aValue);
}
+ (TQNumber *)numberWithUnsignedShort:(unsigned short)aValue
{
    return _TQTaggedNumberCreate(aValue);
}

+ (TQNumber *)numberWithUnsignedInt:(unsigned int)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);

    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithUnsignedInt:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}

+ (TQNumber *)numberWithUnsignedLong:(unsigned long)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);

    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithUnsignedLong:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}

+ (TQNumber *)numberWithUnsignedLongLong:(unsigned long long)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);

    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithUnsignedLongLong:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}

+ (TQNumber *)numberWithUnsignedInteger:(NSUInteger)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);

    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithUnsignedInteger:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}


- (id)initWithBool:(BOOL)aValue
{
    _value = aValue;
    return self;
}
- (id)initWithChar:(char)aValue
{
    _value = aValue;
    return self;
}
- (id)initWithShort:(short)aValue
{
    _value = aValue;
    return self;
}
- (id)initWithInt:(int)aValue
{
    _value = aValue;
    return self;
}
- (id)initWithLong:(long)aValue
{
    _value = aValue;
    return self;
}
- (id)initWithLongLong:(long long)aValue
{
    _value = aValue;
    return self;
}
- (id)initWithFloat:(float)aValue
{
    _value = aValue;
    return self;
}
- (id)initWithDouble:(double)aValue
{
    _value = aValue;
    return self;
}
- (id)initWithInteger:(NSInteger)aValue
{
    _value = aValue;
    return self;
}

- (id)initWithUnsignedChar:(unsigned char)aValue
{
    _value = aValue;
    return self;
}
- (id)initWithUnsignedShort:(unsigned short)aValue
{
    _value = aValue;
    return self;
}
- (id)initWithUnsignedInt:(unsigned int)aValue
{
    _value = aValue;
    return self;
}
- (id)initWithUnsignedLong:(unsigned long)aValue
{
    _value = aValue;
    return self;
}
- (id)initWithUnsignedLongLong:(unsigned long long)aValue
{
    _value = aValue;
    return self;
}
- (id)initWithUnsignedInteger:(NSUInteger)aValue
{
    _value = aValue;
    return self;
}

- (char)charValue                           { return _value; }
- (short)shortValue                         { return _value; }
- (int)intValue                             { return _value; }
- (long)longValue                           { return _value; }
- (long long)longLongValue                  { return _value; }
- (float)floatValue                         { return _value; }
- (double)doubleValue                       { return _value; }
- (BOOL)boolValue                           { return _value; }
- (NSInteger)integerValue                   { return _value; }

- (unsigned char)unsignedCharValue          { return _value; }
- (unsigned short)unsignedShortValue        { return _value; }
- (unsigned int)unsignedIntValue            { return _value; }
- (unsigned long)unsignedLongValue          { return _value; }
- (unsigned long long)unsignedLongLongValue { return _value; }
- (NSUInteger)unsignedIntegerValue          { return _value; }

- (const char *)objCType                    { return "d";                 }
- (void)getValue:(void *)buffer             { *(double *)buffer = _value; }

#pragma mark - Operators

- (id)add:(id)b
{
    if(![b isKindOfClass:[TQNumber class]])
        return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), _TQNumberValue(self) + [b doubleValue]);
    double result = _TQNumberValue(self) + _TQNumberValue(b);
#ifndef TQ_NO_BIGNUM
    if(!_TQNumberCanHold(result))
        return [[TQBigNumber withNumber:self] add:b];
#endif
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), result);

}
- (id)subtract:(id)b
{
    if(![b isKindOfClass:[TQNumber class]])
        return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), _TQNumberValue(self) - [b doubleValue]);
    double result = _TQNumberValue(self) - _TQNumberValue(b);
#ifndef TQ_NO_BIGNUM
    if(!_TQNumberCanHold(result))
        return [[TQBigNumber withNumber:self] subtract:b];
#endif
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), result);
}

- (TQNumber *)negate
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), -_TQNumberValue(self));
}
- (TQNumber *)round
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), round(_TQNumberValue(self)));
}
- (TQNumber *)ceil
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), ceil(_TQNumberValue(self)));
}
- (TQNumber *)floor
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), floor(_TQNumberValue(self)));
}

- (id)multiply:(id)b
{
    if(![b isKindOfClass:[TQNumber class]])
        return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), _TQNumberValue(self) * [b doubleValue]);
    double result = _TQNumberValue(self) * _TQNumberValue(b);
#ifndef TQ_NO_BIGNUM
    if(!_TQNumberCanHold(result))
        return [[TQBigNumber withNumber:self] multiply:b];
#endif
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), result);

}
- (id)divideBy:(id)b
{
    double aVal, bVal;
    aVal = _TQNumberValue(self);
    if(![b isKindOfClass:[TQNumber class]])
        bVal = [b doubleValue];
    else
        bVal = _TQNumberValue(b);
    TQAssert(bVal != 0.0, @"Divide by zero error");

    double result = aVal / bVal;
#ifndef TQ_NO_BIGNUM
    if(!_TQNumberCanHold(result))
        return [[TQBigNumber withNumber:self] divide:b];
#endif
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), result);
}
- (TQNumber *)modulo:(id)b
{
    if(![b isKindOfClass:[TQNumber class]])
        return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), fmod(_TQNumberValue(self), [b doubleValue]));
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), fmod(_TQNumberValue(self), _TQNumberValue(b)));
}
- (id)pow:(id)b
{
    if(![b isKindOfClass:[TQNumber class]])
        return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), pow(_TQNumberValue(self), [b doubleValue]));
    double result = pow(_TQNumberValue(self), _TQNumberValue(b) );
#ifndef TQ_NO_BIGNUM
    if(!_TQNumberCanHold(result))
        return [[TQBigNumber withNumber:self] pow:b];
#endif
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), result);
}
- (TQNumber *)abs
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), fabs(_TQNumberValue(self)));
}
- (TQNumber *)sqrt
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), sqrt(_TQNumberValue(self)));
}
- (TQNumber *)log:(TQNumber *)base;
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), log(_TQNumberValue(self)) / log([base doubleValue]));
}
- (TQNumber *)log
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), log10(_TQNumberValue(self)));
}
- (TQNumber *)log2
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), log(_TQNumberValue(self)));
}
- (TQNumber *)ln
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), log(_TQNumberValue(self)));
}

- (TQNumber *)sine
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), sin(_TQNumberValue(self)));
}
- (TQNumber *)cosine
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), sin(_TQNumberValue(self)));
}
- (TQNumber *)tan
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), tan(_TQNumberValue(self)));
}
- (TQNumber *)hsine
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), sinh(_TQNumberValue(self)));
}
- (TQNumber *)hcosine
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), sinh(_TQNumberValue(self)));
}
- (TQNumber *)htan
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), tanh(_TQNumberValue(self)));
}
- (TQNumber *)arcsine
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), asin(_TQNumberValue(self)));
}
- (TQNumber *)arcosine
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), asin(_TQNumberValue(self)));
}
- (TQNumber *)arctan
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), atan(_TQNumberValue(self)));
}

- (TQNumber *)bitAnd:(id)b
{
    if(![b isKindOfClass:[TQNumber class]])
        return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) & [b longValue]);
    return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) & (long)_TQNumberValue(b));
}

- (TQNumber *)bitOr:(id)b
{
    if(![b isKindOfClass:[TQNumber class]])
        return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) | [b longValue]);
    return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) | (long)_TQNumberValue(b));
}

- (TQNumber *)xor:(id)b
{
    if(![b isKindOfClass:[TQNumber class]])
        return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) ^ [b longValue]);
    return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) ^ (long)_TQNumberValue(b));
}

- (TQNumber *)lshift:(id)b
{
    if(![b isKindOfClass:[TQNumber class]])
        return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) << [b longValue]);
    return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) << (long)_TQNumberValue(b));
}

- (TQNumber *)rshift:(id)b
{
    if(![b isKindOfClass:[TQNumber class]])
        return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) >> [b longValue]);
    return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) >> (long)_TQNumberValue(b));
}


- (id)isEqualTo:(id)b
{
    if(!b)
        return (id)nil;
    else if(![b isKindOfClass:[TQNumber class]])
        return _TQNumberValue(self) == [b doubleValue] ? (id)TQValid : nil;
    return (_TQNumberValue(self) == _TQNumberValue(b)) ? (id)TQValid : nil;

}
- (id)notEqualTo:(id)b
{
    if(!b)
        return (id)nil;
    else if(![b isKindOfClass:[TQNumber class]])
        return _TQNumberValue(self) != [b doubleValue] ? (id)TQValid : (id)nil;
    return (_TQNumberValue(self) != _TQNumberValue(b)) ? (id)TQValid : (id)nil;
}
- (id)isGreaterThan:(id)b
{
    if(![b isKindOfClass:[TQNumber class]])
        return _TQNumberValue(self) > [b doubleValue] ? TQValid : nil;
    return _TQNumberValue(self) > _TQNumberValue(b)   ? TQValid : nil;
}

- (id)isLesserThan:(id)b
{
    if(![b isKindOfClass:[TQNumber class]])
        return _TQNumberValue(self) < [b doubleValue] ? TQValid : nil;
    return _TQNumberValue(self) < _TQNumberValue(b)   ? TQValid : nil;
}

- (id)isGreaterOrEqualTo:(id)b
{
    if(![b isKindOfClass:[TQNumber class]])
        return _TQNumberValue(self) >= [b doubleValue] ? TQValid : nil;
    return _TQNumberValue(self) >= _TQNumberValue(b)   ? TQValid : nil;
}

- (id)isLesserOrEqualTo:(id)b
{
    if(![b isKindOfClass:[TQNumber class]])
        return _TQNumberValue(self) <= [b doubleValue] ? TQValid : nil;
    return _TQNumberValue(self) <= _TQNumberValue(b)   ? TQValid : nil;
}


- (BOOL)isEqual:(id)aObj
{
    if(![aObj isKindOfClass:[TQNumber class]])
        return _TQNumberValue(self) == _TQNumberValue(aObj);
    else if([aObj respondsToSelector:@selector(doubleValue)])
        return _TQNumberValue(self) == [aObj doubleValue];
    return NO;
}

- (NSComparisonResult)compare:(id)aObj
{
    if(![aObj isKindOfClass:[TQNumber class]])
        return NSOrderedAscending;
    TQNumber *b = aObj;
    double value      = _TQNumberValue(self);
    double otherValue = _TQNumberValue(b);
    if(value > otherValue)
        return NSOrderedDescending;
    else if(value < otherValue)
        return NSOrderedAscending;
    else
        return NSOrderedSame;
}

#pragma mark -

- (TQRange *)to:(TQNumber *)b
{
    return [TQRange from:self to:b step:nil];
}

- (TQRange *)to:(TQNumber *)b withStep:(TQNumber *)aStep
{
    return [TQRange from:self to:b step:aStep];
}


#pragma mark -

- (NSString *)description
{
    return [NSString stringWithFormat:@"%0.20g", _TQNumberValue(self)];
}

- (id)times:(id (^)())block
{
    if(TQBlockGetNumberOfArguments(block) == 1) {
        for(int i = 0; i < (int)_TQNumberValue(self); ++i) {
            TQDispatchBlock1(block, [TQNumber numberWithInt:i]);
        }
    } else {
        for(int i = 0; i < (int)_TQNumberValue(self); ++i) {
            TQDispatchBlock0(block);
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)aZone
{
    return [[[self class] numberWithDouble:_value] retain];
}


#pragma mark - Batch allocation code
TQ_BATCH_IMPL(TQNumber)
- (void)dealloc
{
    TQ_BATCH_DEALLOC
}
@end

@implementation TQTaggedNumber
- (char)charValue                           { return _TQTaggedNumberValue(self); }
- (short)shortValue                         { return _TQTaggedNumberValue(self); }
- (int)intValue                             { return _TQTaggedNumberValue(self); }
- (long)longValue                           { return _TQTaggedNumberValue(self); }
- (long long)longLongValue                  { return _TQTaggedNumberValue(self); }
- (float)floatValue                         { return _TQTaggedNumberValue(self); }
- (double)doubleValue                       { return _TQTaggedNumberValue(self); }
- (BOOL)boolValue                           { return _TQTaggedNumberValue(self); }
- (NSInteger)integerValue                   { return _TQTaggedNumberValue(self); }

- (unsigned char)unsignedCharValue          { return _TQTaggedNumberValue(self); }
- (unsigned short)unsignedShortValue        { return _TQTaggedNumberValue(self); }
- (unsigned int)unsignedIntValue            { return _TQTaggedNumberValue(self); }
- (unsigned long)unsignedLongValue          { return _TQTaggedNumberValue(self); }
- (unsigned long long)unsignedLongLongValue { return _TQTaggedNumberValue(self); }
- (NSUInteger)unsignedIntegerValue          { return _TQTaggedNumberValue(self); }

- (const char *)objCType        { return "f";                                    }
- (void)getValue:(void *)buffer { *(float *)buffer = _TQTaggedNumberValue(self); }

+ (id)allocWithZone:(NSZone *)aZone  { return nil; }
- (id)retain { return self;}
- (oneway void)release {}
- (id)autorelease { return self; }
- (void)dealloc { if(NO) [super dealloc]; }
- (id)copyWithZone:(NSZone *)aZone { return self; }
@end

