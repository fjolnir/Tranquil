// TODO: Find a way to forward messages with ObjFW!!
#import "TQPromise.h"
#import "TQValidObject.h"
#import "../Shared/TQDebug.h"
#import "OFObject+TQAdditions.h"
#import <objc/runtime.h>
#import <unistd.h>

@interface TQPromise ()  {
    @public
    OFObject *_result;
}
@end

static OFString *const _TQPromiseNotResolvedSentinel = @"550e8400e29b41d4a716446655440000";

static __inline__ OFObject *TQPromiseGetResult(TQPromise *p)
{
    TQAssert(p->_result != _TQPromiseNotResolvedSentinel, @"Sent a message to an unfulfilled promise.");
    return p->_result;
}

@implementation TQPromise

+ (TQPromise *)promise
{
    TQPromise *ret = [self alloc];
    ret->_result = [_TQPromiseNotResolvedSentinel retain];
    return [ret autorelease];
}

- (void)dealloc
{
    [_result release];
    [super dealloc];
}

- (void)fulfillWith:(id)aResult
{
    TQAssert(__sync_bool_compare_and_swap(&_result, _TQPromiseNotResolvedSentinel, aResult), @"A promise can only be fulfilled once.");
    [_result retain];
}

- (id)fulfilled
{
    return _result == _TQPromiseNotResolvedSentinel ? nil : [TQValidObject valid];
}

- (id)waitTillFulfilled
{
    while(self->_result == _TQPromiseNotResolvedSentinel) usleep(100);
    return _result;
}

- (id)print
{
    if(_result != _TQPromiseNotResolvedSentinel)
        return [_result print];
    return [[self description] print];
}

- (OFString *)description
{
    if(_result != _TQPromiseNotResolvedSentinel)
        return [_result description];
    return [OFString stringWithFormat:@"<%s: %p (Unresolved)>", class_getName([super class]), self];
}
- (Class)class
{
    return [TQPromiseGetResult(self) class];
}
- (uint32_t)hash
{
    return [TQPromiseGetResult(self) hash];
}

- (BOOL)isEqual:(id)anObject
{
    return [TQPromiseGetResult(self) isEqual:anObject];
}

- (id)self
{
    return (id)TQPromiseGetResult(self);
}
@end
