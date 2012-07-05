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

+ (TQNumber *)numberWithDouble:(double)aValue
{
    // This one gets called quite frequently, so we cache the imps required to allocate
    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), nil), @selector(initWithDouble:), aValue);
    return autoreleaseImp(ret, @selector(autorelease));
}

- (id)initWithDouble:(double)aValue
{
    _value = aValue;
    return self;
}

- (TQNumber *)add:(TQNumber *)b
{
    if(isa != object_getClass(b)) return nil;
    return numberWithDoubleImp(isa, @selector(numberWithDouble:), _value + b->_value);
}
- (TQNumber *)subtract:(TQNumber *)b
{
    if(isa != object_getClass(b)) return nil;
    return numberWithDoubleImp(isa, @selector(numberWithDouble:), _value - b->_value);
}
- (TQNumber *)negate
{
    return numberWithDoubleImp(isa, @selector(numberWithDouble:), -_value);
}

- (TQNumber *)multiply:(TQNumber *)b
{
    if(isa != object_getClass(b)) return nil;
    return numberWithDoubleImp(isa, @selector(numberWithDouble:), _value * b->_value);
}
- (TQNumber *)divideBy:(TQNumber *)b
{
    if(isa != object_getClass(b)) return nil;
    return numberWithDoubleImp(isa, @selector(numberWithDouble:), _value / b->_value);
}

- (TQNumber *)isGreater:(TQNumber *)b
{
    if(isa != object_getClass(b)) return nil;
    return _value > b->_value ? TQValid : nil;
}

- (TQNumber *)isLesser:(TQNumber *)b
{
    if(isa != object_getClass(b)) return nil;
    return _value < b->_value ? TQValid : nil;
}

- (TQNumber *)isGreaterOrEqual:(TQNumber *)b
{
    if(isa != object_getClass(b)) return nil;
    return _value >= b->_value ? TQValid : nil;
}

- (TQNumber *)isLesserOrEqual:(TQNumber *)b
{
    if(isa != object_getClass(b)) return nil;
    return _value <= b->_value ? TQValid : nil;
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
    if(_value > b->_value)
        return NSOrderedDescending;
    else if(_value < b->_value)
        return NSOrderedAscending;
    else
        return NSOrderedSame;
}

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


TQ_BATCH_IMPL(TQNumber)
@end
