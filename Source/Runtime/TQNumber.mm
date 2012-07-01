#import "TQNumber.h"
#import <objc/runtime.h>
#import "TQRuntime.h"

static struct {
    TQNumber *lastElement;
} _Pool = { nil };

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
    if(self->isa != object_getClass(b)) return nil;
    return numberWithDoubleImp(self->isa, @selector(numberWithDouble), _value + b->_value);
}
- (TQNumber *)subtract:(TQNumber *)b
{
    if(self->isa != object_getClass(b)) return nil;
    return numberWithDoubleImp(self->isa, @selector(numberWithDouble:), _value - b->_value);
}
- (TQNumber *)negate
{
    return numberWithDoubleImp(self->isa, @selector(numberWithDouble:), -_value);
}

- (TQNumber *)multiply:(TQNumber *)b
{
    if(self->isa != object_getClass(b)) return nil;
    return numberWithDoubleImp(self->isa, @selector(numberWithDouble:), _value * b->_value);
}
- (TQNumber *)divideBy:(TQNumber *)b
{
    if(self->isa != object_getClass(b)) return nil;
    return numberWithDoubleImp(self->isa, @selector(numberWithDouble:), _value / b->_value);
}

- (TQNumber *)isGreater:(TQNumber *)b
{
    if(self->isa != object_getClass(b)) return nil;
    return _value > b->_value ? TQNumberTrue : TQNumberFalse;
}

- (TQNumber *)isLesser:(TQNumber *)b
{
    if(self->isa != object_getClass(b)) return nil;
    return _value < b->_value ? TQNumberTrue : TQNumberFalse;
}

- (TQNumber *)isGreaterOrEqual:(TQNumber *)b
{
    if(self->isa != object_getClass(b)) return nil;
    return _value >= b->_value ? TQNumberTrue : TQNumberFalse;
}

- (TQNumber *)isLesserOrEqual:(TQNumber *)b
{
    if(self->isa != object_getClass(b)) return nil;
    return _value <= b->_value ? TQNumberTrue : TQNumberFalse;
}


- (BOOL)isEqual:(id)aObj
{
    if(self->isa == object_getClass(aObj))
        return self->_value == ((TQNumber *)aObj)->_value;
    return NO;
}

- (NSComparisonResult)compare:(id)object
{
    if(object_getClass(object) != self->isa)
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

#pragma mark - Allocation pooling

+ (id)allocWithZone:(NSZone *)aZone
{
    if(!_Pool.lastElement) {
        TQNumber *object = NSAllocateObject(self, 0, aZone);
        object->_retainCount = 1;
        return object;
    }
    else {
        TQNumber *object = _Pool.lastElement;
        _Pool.lastElement = object->_poolPredecessor;

        object->_retainCount = 1;
        return object;
    }
}

- (NSUInteger)retainCount
{
    return _retainCount;
}

- (id)retain
{
    __sync_add_and_fetch(&_retainCount, 1);
    return self;
}

- (oneway void)release
{
    if(!__sync_sub_and_fetch(&_retainCount, 1))
    {
        _poolPredecessor = _Pool.lastElement;
        _Pool.lastElement = self;
    }
}

- (void)_purge
{
    // Actually deallocate the object
    [super release];
}

+ (int)purgeCache
{
    TQNumber *lastElement;
    int count=0;
    while ((lastElement = _Pool.lastElement))
    {
        ++count;
        _Pool.lastElement = lastElement->_poolPredecessor;
        [lastElement _purge];
    }
    return count;
}
@end
