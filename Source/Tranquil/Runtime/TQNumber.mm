#import "TQNumber.h"
#import <objc/runtime.h>
#import "TQRuntime.h"

static id (*numberWithDoubleImp)(id, SEL, double)  ;
static IMP allocImp, initImp, autoreleaseImp;

TQNumber *TQNumberTrue;
TQNumber *TQNumberFalse;

// Hack from libobjc, allows tail call optimization for objc_msgSend
extern id _objc_msgSend_hack(id, SEL)          asm("_objc_msgSend");
extern id _objc_msgSend_hack2(id, SEL, id)     asm("_objc_msgSend");

@implementation TQNumber
@synthesize doubleValue=_value;

+ (void)load
{
    if(self != [TQNumber class]) {
        NSLog(@"Warning: Subclassing TQNumber is a bad idea!");
        // These cannot be overridden
        assert(method_getImplementation(class_getClassMethod(self, @selector(allocWithZone:))) == allocImp);
        assert(class_getMethodImplementation(self, @selector(init)) == initImp);
        assert(class_getMethodImplementation(self, @selector(autorelease)) == autoreleaseImp);
    }
    numberWithDoubleImp = (id (*)(id, SEL, double))method_getImplementation(class_getClassMethod(self, @selector(numberWithDouble:)));
    allocImp = method_getImplementation(class_getClassMethod(self, @selector(allocWithZone:)));
    initImp = class_getMethodImplementation(self, @selector(init));
    autoreleaseImp = class_getMethodImplementation(self, @selector(autorelease));

    TQNumberTrue = [[self alloc] init];
    TQNumberTrue->_value = 1;
    TQNumberFalse = nil;
}


+ (TQNumber *)numberWithDouble:(double)aValue
{
    // This one gets called quite frequently, so we cache the imps required to allocate
    TQNumber *ret = initImp(allocImp(self, @selector(allocWithZone:), NSDefaultMallocZone), @selector(init));
    ret->_value = aValue;
    return autoreleaseImp(ret, @selector(autorelease));
}

- (TQNumber *)add:(TQNumber *)b
{
    if(object_getClass(self) != object_getClass(b)) return nil;
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble), _value + b->_value);
}
- (TQNumber *)subtract:(TQNumber *)b
{
    if(object_getClass(self) != object_getClass(b)) return nil;
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), _value - b->_value);
}
- (TQNumber *)negate
{
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), -_value);
}

- (TQNumber *)multiply:(TQNumber *)b
{
    if(object_getClass(self) != object_getClass(b)) return nil;
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), _value * b->_value);
}
- (TQNumber *)divideBy:(TQNumber *)b
{
    if(object_getClass(self) != object_getClass(b)) return nil;
    return numberWithDoubleImp(object_getClass(self), @selector(numberWithDouble:), _value / b->_value);
}

- (TQNumber *)isGreater:(TQNumber *)b
{
    if(object_getClass(self) != object_getClass(b)) return nil;
    return _value > b->_value ? TQNumberTrue : TQNumberFalse;
}

- (TQNumber *)isLesser:(TQNumber *)b
{
    if(object_getClass(self) != object_getClass(b)) return nil;
    return _value < b->_value ? TQNumberTrue : TQNumberFalse;
}

- (TQNumber *)isGreaterOrEqual:(TQNumber *)b
{
    if(object_getClass(self) != object_getClass(b)) return nil;
    return _value >= b->_value ? TQNumberTrue : TQNumberFalse;
}

- (TQNumber *)isLesserOrEqual:(TQNumber *)b
{
    if(object_getClass(self) != object_getClass(b)) return nil;
    return _value <= b->_value ? TQNumberTrue : TQNumberFalse;
}


- (BOOL)isEqual:(id)aObj
{
    if(object_getClass(self) == object_getClass(aObj))
        return self->_value == ((TQNumber *)aObj)->_value;
    return NO;
}

- (NSComparisonResult)compare:(id)object
{
    if(object_getClass(object) != object_getClass(self))
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

TQ_POOL_IMPLEMENTATION

@end
