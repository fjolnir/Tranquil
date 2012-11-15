#import "TQNumber.h"
#import <objc/runtime.h>
#import "TQRuntime.h"
#import "TQRange.h"
#import "TQBigNumber.h"
#import "../../../Build/TQStubs.h"

@interface TQTaggedNumber : TQNumber
@end

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

#define IS_TAGGED(ptr) ((uintptr_t)(ptr) & 1)

#ifdef __LP64__
// Largest integer accurately representable
static const double TQTaggedNumberLimit = 1.0f/FLT_EPSILON;
#endif

union CoercedValue {
    void *ptr;
    uintptr_t addr;
    float floatValue;
    double doubleValue;
};

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

static __inline__ id _TQTaggedNumberCreate(float value)
{
    union CoercedValue val = { .floatValue = value };
    val.addr = (val.addr << 4) | kTQNumberTag;
    return val.ptr;
}

static __inline__ float _TQTaggedNumberValue(TQTaggedNumber *ptr)
{
    union CoercedValue val = { .ptr = ptr };
    val.addr >>= 4;
    return val.floatValue;
}
static __inline__ double _TQNumberValue(TQNumber *ptr)
{
    return IS_TAGGED(ptr) ? _TQTaggedNumberValue((TQTaggedNumber *)ptr) : ptr->_value;
}

BOOL TQFloatFitsInTaggedNumber(float aValue)
{
    return _TQTaggedNumberCanHold(aValue);
}

@implementation TQTaggedNumber
- (id)retain { return self;}
- (oneway void)release {}
- (id)autorelease { return self; }
- (void)dealloc { if(NO) [super dealloc]; }
- (id)copyWithZone:(NSZone *)aZone { return self; }
@end

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

        IMP imp;
        // ==
        imp = imp_implementationWithBlock(^(TQNumber *a, id b) {
            if(!b)
                return (id)nil;
            else if(object_getClass(a) != object_getClass(b))
                return _TQNumberValue(a) == [b doubleValue] ? (id)TQValid : nil;
            return (_TQNumberValue(a) == _TQNumberValue(b)) ? (id)TQValid : nil;
        });
        class_replaceMethod(TQNumberClass, TQEqOpSel, imp, "@@:@");
        // !=
        imp = imp_implementationWithBlock(^(TQNumber *a, id b) {
            if(!b)
                return (id)nil;
            else if(object_getClass(a) != object_getClass(b))
                return _TQNumberValue(a) != [b doubleValue] ? (id)TQValid : (id)nil;
            return (_TQNumberValue(a) != _TQNumberValue(b)) ? (id)TQValid : (id)nil;
        });
        class_replaceMethod(TQNumberClass, TQNeqOpSel, imp, "@@:@");

        class_replaceMethod(TQNumberClass, TQAddOpSel,  class_getMethodImplementation(TQNumberClass, @selector(add:)),             "@@:@");
        class_replaceMethod(TQNumberClass, TQSubOpSel,  class_getMethodImplementation(TQNumberClass, @selector(subtract:)),        "@@:@");
        class_replaceMethod(TQNumberClass, TQUnaryMinusOpSel, class_getMethodImplementation(TQNumberClass, @selector(negate)),     "@@:" );
        class_replaceMethod(TQNumberClass, TQMultOpSel, class_getMethodImplementation(TQNumberClass, @selector(multiply:)),        "@@:@");
        class_replaceMethod(TQNumberClass, TQDivOpSel,  class_getMethodImplementation(TQNumberClass, @selector(divideBy:)),        "@@:@");
        class_replaceMethod(TQNumberClass, TQModOpSel,  class_getMethodImplementation(TQNumberClass, @selector(modulo:)),          "@@:@");

        class_replaceMethod(TQNumberClass, TQLTOpSel,  class_getMethodImplementation(TQNumberClass, @selector(isLesser:)),         "@@:@");
        class_replaceMethod(TQNumberClass, TQGTOpSel,  class_getMethodImplementation(TQNumberClass, @selector(isGreater:)),        "@@:@");
        class_replaceMethod(TQNumberClass, TQLTEOpSel, class_getMethodImplementation(TQNumberClass, @selector(isLesserOrEqual:)),  "@@:@");
        class_replaceMethod(TQNumberClass, TQGTEOpSel, class_getMethodImplementation(TQNumberClass, @selector(isGreaterOrEqual:)), "@@:@");
        class_replaceMethod(TQNumberClass, TQExpOpSel, class_getMethodImplementation(TQNumberClass, @selector(pow:)),              "@@:@");
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
        kTQArchitectureX86_64:
        kTQArchitectureHost:
            return [self fitsInTaggedPointer:aValue];
            break;
        default:
            return NO;
    }
}

+ (TQNumber *)numberWithBool:(BOOL)aValue
{
    return _TQTaggedNumberCreate(aValue);
}
+ (TQNumber *)numberWithChar:(char)aValue
{
    return _TQTaggedNumberCreate(aValue);
}
+ (TQNumber *)numberWithShort:(short)aValue
{
    return _TQTaggedNumberCreate(aValue);
}
+ (TQNumber *)numberWithInt:(int)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);

    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithInt:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithLong:(long)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);

    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithLong:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithLongLong:(long long)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);

    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithLongLong:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithFloat:(float)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);

    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithFloat:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithDouble:(double)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);

    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithDouble:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithInteger:(NSInteger)aValue
{
    if(_TQTaggedNumberCanHold(aValue))
        return _TQTaggedNumberCreate(aValue);

    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithInteger:), aValue);
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


- (char)charValue { return _TQNumberValue(self); }
- (short)shortValue { return _TQNumberValue(self); }
- (int)intValue { return _TQNumberValue(self); }
- (long)longValue { return _TQNumberValue(self); }
- (long long)longLongValue { return _TQNumberValue(self); }
- (float)floatValue { return _TQNumberValue(self); }
- (double)doubleValue { return _TQNumberValue(self); }
- (BOOL)boolValue { return _TQNumberValue(self); }
- (NSInteger)integerValue { return _TQNumberValue(self); }

- (unsigned char)unsignedCharValue { return _TQNumberValue(self); }
- (unsigned short)unsignedShortValue { return _TQNumberValue(self); }
- (unsigned int)unsignedIntValue { return _TQNumberValue(self); }
- (unsigned long)unsignedLongValue { return _TQNumberValue(self); }
- (unsigned long long)unsignedLongLongValue { return _TQNumberValue(self); }
- (NSUInteger)unsignedIntegerValue { return _TQNumberValue(self); }

- (const char *)objCType { return "d"; }
- (void)getValue:(void *)buffer { *(double *)buffer = _TQNumberValue(self); }

#pragma mark - Operators

- (id)add:(id)b
{
    if(object_getClass(self) != object_getClass(b))
        return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), _TQNumberValue(self) + [b doubleValue]);
    double result = _TQNumberValue(self) + _TQNumberValue(b);
#ifndef TQ_NO_BIGNUM
    if(isinf(result))
        return [[TQBigNumber withNumber:self] add:b];
#endif
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), result);

}
- (id)subtract:(id)b
{
    if(object_getClass(self) != object_getClass(b))
        return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), _TQNumberValue(self) - [b doubleValue]);
    double result = _TQNumberValue(self) - _TQNumberValue(b);
#ifndef TQ_NO_BIGNUM
    if(isinf(result))
        return [[TQBigNumber withNumber:self] subtract:b];
#endif
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), result);
}

- (TQNumber *)negate
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), -_TQNumberValue(self));
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
    if(object_getClass(self) != object_getClass(b))
        return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), _TQNumberValue(self) * [b doubleValue]);
    double result = _TQNumberValue(self) * _TQNumberValue(b);
#ifndef TQ_NO_BIGNUM
    if(isinf(result))
        return [[TQBigNumber withNumber:self] multiply:b];
#endif
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), result);

}
- (id)divideBy:(id)b
{
    double aVal, bVal;
    aVal = _TQNumberValue(self);
    if(object_getClass(self) != object_getClass(b))
        bVal = [b doubleValue];
    else
        bVal = _TQNumberValue(b);
    TQAssert(bVal != 0.0, @"Divide by zero error");

    double result = aVal / bVal;
#ifndef TQ_NO_BIGNUM
    if(isinf(result))
        return [[TQBigNumber withNumber:self] divide:b];
#endif
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), result);
}
- (TQNumber *)modulo:(id)b
{
    if(object_getClass(self) != object_getClass(b))
        return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), fmod(_TQNumberValue(self), [b doubleValue]));
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), fmod(_TQNumberValue(self), _TQNumberValue(b)));
}
- (id)pow:(id)b
{
    if(object_getClass(self) != object_getClass(b))
        return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), pow(_TQNumberValue(self), [b doubleValue]));
    double result = pow(_TQNumberValue(self), _TQNumberValue(b) );
#ifndef TQ_NO_BIGNUM
    if(isinf(result))
        return [[TQBigNumber withNumber:self] pow:b];
#endif
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), result);
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
    if(object_getClass(self) != object_getClass(b))
        return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) & [b longValue]);
    return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) & (long)_TQNumberValue(b));
}

- (TQNumber *)bitOr:(id)b
{
    if(object_getClass(self) != object_getClass(b))
        return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) | [b longValue]);
    return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) | (long)_TQNumberValue(b));
}

- (TQNumber *)xor:(id)b
{
    if(object_getClass(self) != object_getClass(b))
        return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) ^ [b longValue]);
    return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) ^ (long)_TQNumberValue(b));
}

- (TQNumber *)lshift:(id)b
{
    if(object_getClass(self) != object_getClass(b))
        return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) << [b longValue]);
    return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) << (long)_TQNumberValue(b));
}

- (TQNumber *)rshift:(id)b
{
    if(object_getClass(self) != object_getClass(b))
        return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) >> [b longValue]);
    return numberWithLongImp(object_getClass(self), @selector(numberWithLong:), (long)_TQNumberValue(self) >> (long)_TQNumberValue(b));
}


- (id)isGreater:(id)b
{
    if(object_getClass(self) != object_getClass(b))
        return _TQNumberValue(self) > [b doubleValue] ? TQValid : nil;
    return _TQNumberValue(self) > _TQNumberValue(b)  ? TQValid : nil;
}

- (id)isLesser:(id)b
{
    if(object_getClass(self) != object_getClass(b))
        return _TQNumberValue(self) < [b doubleValue] ? TQValid : nil;
    return _TQNumberValue(self) < _TQNumberValue(b)  ? TQValid : nil;
}

- (id)isGreaterOrEqual:(id)b
{
    if(object_getClass(self) != object_getClass(b))
        return _TQNumberValue(self) >= [b doubleValue] ? TQValid : nil;
    return _TQNumberValue(self) >= _TQNumberValue(b)  ? TQValid : nil;
}

- (id)isLesserOrEqual:(id)b
{
    if(object_getClass(self) != object_getClass(b))
        return _TQNumberValue(self) <= [b doubleValue] ? TQValid : nil;
    return _TQNumberValue(self) <= _TQNumberValue(b)  ? TQValid : nil;
}


- (BOOL)isEqual:(id)aObj
{
    if(object_getClass(self) == object_getClass(aObj))
        return _TQNumberValue(self) == _TQNumberValue(aObj);
    else if([aObj respondsToSelector:@selector(doubleValue)])
        return _TQNumberValue(self) == [aObj doubleValue];
    return NO;
}

- (NSComparisonResult)compare:(id)object
{
    if(object_getClass(object) != object_getClass(self))
        return NSOrderedAscending;
    TQNumber *b = object;
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
    return [TQRange from:self to:b];
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
