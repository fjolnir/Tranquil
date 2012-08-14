// This should work ..if everyone did their retains like foo = [foo retain]; rather than just [foo retain];
#import <Tranquil/Runtime/TQNumber.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

#define TQStackObjAlloc(Klass) (id)&(struct {@defs(Klass)} *){[Klass class]}

@interface TQStackObject {
    Class isa;
    @protected
    id forwarding; // This points to the actual object (initially to itself)
}
- (id)copy;
- (id)autoreleasedCopy;
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector;
- (void)doesNotRecognizeSelector:(SEL)aSelector;
- (Class)class;
- (id)self;
- (id)superclass;
- (BOOL)isEqual:(id)aCounterPart;
- (BOOL)isKindOfClass:(Class)aClass;
- (BOOL)isMemberOfClass:(Class)aClass;
- (BOOL)respondsToSelector:(SEL)aSel;
- (BOOL)conformsToProtocol:(Protocol *)aProtocol;
- (id)performSelector:(SEL)aSelector;
- (id)performSelector:(SEL)aSelector withObject:(id)anObject;
- (id)performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject;
- (BOOL)isProxy;
- (NSString *)description;
@end

@implementation TQStackObject

- (id)init
{
    forwarding = self;
    return self;
}

- (id)performCopy
{
    [NSException raise:NSGenericException format:@"-copy not implemented for class %@", [self class]];
}

- (id)copy
{
    if(self == self->forwarding)
        return [self performCopy];
    return return [self->forwarding retain];
}

- (id)autoreleasedCopy
{
    return [[self copy] autorelease];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    Method method = class_getInstanceMethod(self->forwarding->isa, aSelector);
    if(!method)
        return nil;
    return [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(method)];
}

- (void)doesNotRecognizeSelector:(SEL)aSelector
{
    [NSException raise:NSInvalidArgumentException
                format:@"unrecognized selector '%@' sent to class %p",
                       NSStringFromSelector(aSelector), [self class]];
}

- (Class)class
{
    return self->forwarding->isa;
}

- (id)self
{
    return self->forwarding;
}

- (id)superclass
{
    return class_getSuperclass([self class]);
}
- (BOOL)isEqual:(id)aCounterPart
{
    return self == aCounterPart || self->forwarding == aCounterPart;
}

- (BOOL)isKindOfClass:(Class)aClass
{
    register Class kls;
    for(kls = self->forwarding->isa; kls; kls = class_getSuperclass(kls)) {
        if(kls == aClass)
            return YES;
    }
    return NO;
}
- (BOOL)isMemberOfClass:(Class)aClass
{
    return self->forwarding->isa == aClass;
}
- (BOOL)respondsToSelector:(SEL)aSel
{
    return class_getInstanceMethod([self class], aSel) != nil;
}
- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return class_conformsToProtocol([self class], aProtocol);
}
- (id)performSelector:(SEL)aSelector
{
    return objc_msgSend(self->forwarding, aSelector);
}
- (id)performSelector:(SEL)aSelector withObject:(id)anObject
{
    return objc_msgSend(self->forwarding, aSelector, anObject);
}
- (id)performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject
{
    return objc_msgSend(self->forwarding, aSelector, anObject, anotherObject);
}
- (BOOL)isProxy
{
    return NO;
}
- (NSString *)description
{
    Class kls = [self class];
    return [NSString stringWithFormat:@"<%s: %p>", class_getName(kls), kls];
}

// These are just here to catch errors
- (id)retain
{
    return [self copy];
}
- (NSUInteger)retainCount
{
    return UINT_MAX;
}
- (oneway void)release
{
    [NSException raise:NSGenericException format:@"Releasing a stack object makes no sense"];
}
@end

@interface TQStackNumber : TQStackObject {
    double _value;
}
- (double)value;
- (void)setValue:(double)aValue;
@end

@implementation TQStackNumber

- (id)performCopy
{
    self->forwarding = [[TQNumber numberWithDouble:_value] retain];
    return self->forwarding;
}

- (double)value
{
    return ((TQStackNumber *)self->forwarding)->value;
}
- (void)setValue:(double)aValue
{
    ((TQStackNumber *)self->forwarding)->value = aValue;
}
- (BOOL)isEqual:(id)aCounterPart
{
    Class otherClass = [aCounterPart class];
    if(self->isa == otherClass || self->forwarding->isa == otherClass)
        return [self value] == [aCounterPart doubleValue];
    return NO;
}
@end

int main(int argc, char *argv[]) {
    NSAutoreleasePool *p = [NSAutoreleasePool new];

    struct { id isa; double value; } stackObj = { NSClassFromString(@"TQStackNumber"), &stackObj, 0.0 };
    TQStackNumber *stackObjPtr = (TQStackNumber *)&stackObj;
    [stackObjPtr setValue:3];

    NSLog(@"%f %@", [stackObjPtr value], [stackObjPtr description]);

    [p release];
}
