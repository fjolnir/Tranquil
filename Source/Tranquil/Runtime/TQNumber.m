#import "TQNumber.h"
#import <objc/runtime.h>
#import "TQRuntime.h"

static id (*numberWithDoubleImp)(id, SEL, double)  ;
static id (*allocImp)(id,SEL,NSZone*);
static id (*initImp)(id,SEL,double);
static id (*autoreleaseImp)(id,SEL);

// Hack from libobjc, allows tail call optimization for objc_msgSend
extern id _objc_msgSend_hack(id, SEL)          asm("_objc_msgSend");
extern id _objc_msgSend_hack2(id, SEL, id)     asm("_objc_msgSend");

@implementation TQNumber
@synthesize value=_value;

+ (void)load
{
    if(self != [TQNumber class]) {
        NSLog(@"Warning: Subclassing TQNumber is a bad idea!");
        // These cannot be overridden
        assert((typeof(allocImp))method_getImplementation(class_getClassMethod(self, @selector(allocWithZone:))) == allocImp);
        assert((typeof(initImp))class_getMethodImplementation(self, @selector(initWithDouble:)) == initImp);
        assert((typeof(autoreleaseImp))class_getMethodImplementation(self, @selector(autorelease)) == autoreleaseImp);
    }
    numberWithDoubleImp = (id (*)(id, SEL, double))method_getImplementation(class_getClassMethod(self, @selector(numberWithDouble:)));
    allocImp = (typeof(allocImp))method_getImplementation(class_getClassMethod(self, @selector(allocWithZone:)));
    initImp = (typeof(initImp))class_getMethodImplementation(self, @selector(initWithDouble:));
    autoreleaseImp = (typeof(autoreleaseImp))class_getMethodImplementation(self, @selector(autorelease));
}

+ (TQNumber *)numberWithBool:(BOOL)aValue
{
    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithBool:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithChar:(char)aValue
{
    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithDouble:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithShort:(short)aValue
{
    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithShort:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithInt:(int)aValue
{
    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithInt:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithLong:(long)aValue
{
    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithLong:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithLongLong:(long long)aValue
{
    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithLongLong:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithFloat:(float)aValue
{
    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithFloat:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithDouble:(double)aValue
{
    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithDouble:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}
+ (TQNumber *)numberWithInteger:(NSInteger)aValue
{
    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithInteger:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}

+ (NSNumber *)numberWithUnsignedChar:(unsigned char)aValue
{
    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithUnsignedChar:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}

+ (NSNumber *)numberWithUnsignedShort:(unsigned short)aValue
{
    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithUnsignedShort:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}

+ (NSNumber *)numberWithUnsignedInt:(unsigned int)aValue
{
    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithUnsignedInt:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}

+ (NSNumber *)numberWithUnsignedLong:(unsigned long)aValue
{
    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithUnsignedLong:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}

+ (NSNumber *)numberWithUnsignedLongLong:(unsigned long long)aValue
{
    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithUnsignedLongLong:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}

+ (NSNumber *)numberWithUnsignedInteger:(NSUInteger)aValue
{
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


- (char)charValue { return _value; }
- (short)shortValue { return _value; }
- (int)intValue { return _value; }
- (long)longValue { return _value; }
- (long long)longLongValue { return _value; }
- (float)floatValue { return _value; }
- (double)doubleValue { return _value; }
- (BOOL)boolValue { return _value; }
- (NSInteger)integerValue { return _value; }

- (unsigned char)unsignedCharValue { return _value; }
- (unsigned short)unsignedShortValue { return _value; }
- (unsigned int)unsignedIntValue { return _value; }
- (unsigned long)unsignedLongValue { return _value; }
- (unsigned long long)unsignedLongLongValue { return _value; }
- (NSUInteger)unsignedIntegerValue { return _value; }

#pragma mark - Operators

- (TQNumber *)add:(id)b
{
    if(isa != object_getClass(b))
        return numberWithDoubleImp(isa, @selector(numberWithDouble:), _value + [b doubleValue]);
    return numberWithDoubleImp(isa, @selector(numberWithDouble:), _value + ((TQNumber*)b)->_value);
}
- (TQNumber *)subtract:(id)b
{
    if(isa != object_getClass(b))
        return numberWithDoubleImp(isa, @selector(numberWithDouble:), _value - [b doubleValue]);
    return numberWithDoubleImp(isa, @selector(numberWithDouble:), _value - ((TQNumber*)b)->_value);
}

- (TQNumber *)negate
{
    return numberWithDoubleImp(isa, @selector(numberWithDouble:), -_value);
}
- (TQNumber *)ceil
{
    return numberWithDoubleImp(isa, @selector(numberWithDouble:), ceil(_value));
}
- (TQNumber *)floor
{
    return numberWithDoubleImp(isa, @selector(numberWithDouble:), floor(_value));
}

- (TQNumber *)multiply:(id)b
{
    if(isa != object_getClass(b))
        return numberWithDoubleImp(isa, @selector(numberWithDouble:), _value * [b doubleValue]);
    return numberWithDoubleImp(isa, @selector(numberWithDouble:), _value * ((TQNumber*)b)->_value);
}
- (TQNumber *)divideBy:(id)b
{
    if(isa != object_getClass(b))
        return numberWithDoubleImp(isa, @selector(numberWithDouble:), _value / [b doubleValue]);
    return numberWithDoubleImp(isa, @selector(numberWithDouble:), _value / ((TQNumber*)b)->_value);
}

- (TQNumber *)pow:(id)b
{
    if(isa != object_getClass(b))
        return numberWithDoubleImp(isa, @selector(numberWithDouble:), pow(_value, [b doubleValue]));
    return numberWithDoubleImp(isa, @selector(numberWithDouble:), pow(_value, ((TQNumber*)b)->_value));
}

- (TQNumber *)isGreater:(id)b
{
    if(isa != object_getClass(b))
        return _value > [b doubleValue] ? (TQNumber*)TQValid : nil;
    return _value > ((TQNumber*)b)->_value ? (TQNumber*)TQValid : nil;
}

- (TQNumber *)isLesser:(id)b
{
    if(isa != object_getClass(b))
        return _value < [b doubleValue] ? (TQNumber*)TQValid : nil;
    return _value < ((TQNumber*)b)->_value ? (TQNumber*)TQValid : nil;
}

- (TQNumber *)isGreaterOrEqual:(id)b
{
    if(isa != object_getClass(b))
        return _value >= [b doubleValue] ? (TQNumber*)TQValid : nil;
    return _value >= ((TQNumber*)b)->_value ? (TQNumber*)TQValid : nil;
}

- (TQNumber *)isLesserOrEqual:(id)b
{
    if(isa != object_getClass(b))
        return _value <= [b doubleValue] ? (TQNumber*)TQValid : nil;
    return _value <= ((TQNumber*)b)->_value ? (TQNumber*)TQValid : nil;
}


- (BOOL)isEqual:(id)aObj
{
    if(isa == object_getClass(aObj))
        return self->_value == ((TQNumber *)aObj)->_value;
    return NO;
}

- (NSComparisonResult)compare:(id)object
{
    if(object_getClass(object) != isa)
        return NSOrderedAscending;
    TQNumber *b = object;
    if(_value > ((TQNumber*)b)->_value)
        return NSOrderedDescending;
    else if(_value < ((TQNumber*)b)->_value)
        return NSOrderedAscending;
    else
        return NSOrderedSame;
}

#pragma mark -

- (NSString *)description
{
    return [NSString stringWithFormat:@"%f", _value];
}

id TQDispatchBlock0(struct TQBlockLiteral *block) __asm("_TQDispatchBlock0");
- (id)times:(id (^)())block
{
    for(int i = 0; i < (int)_value; ++i) {
        TQDispatchBlock0((struct TQBlockLiteral *)block);
    }
    return nil;
}


#pragma mark - Batch allocation code
TQ_BATCH_IMPL(TQNumber)
- (void)dealloc
{
    TQ_BATCH_DEALLOC
}
@end
