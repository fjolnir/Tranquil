#import "TQPromise.h"
#import "TQValidObject.h"
#import "NSObject+TQAdditions.h"
#import "NSString+TQAdditions.h"

#import <objc/runtime.h>

@interface TQPromise ()  {
    @public
    id _result;
}
@end

static NSString *const _TQPromiseNotResolvedSentinel = @"550e8400e29b41d4a716446655440000";

static __inline__ id TQPromiseGetResult(TQPromise *p)
{
    if(p->_result != _TQPromiseNotResolvedSentinel)
        return p->_result;
    [[NSException exceptionWithName:NSInvalidArgumentException
                             reason:@"Sent a message to an unfulfilled promise."
                           userInfo:nil] raise];
    return nil;
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

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return TQPromiseGetResult(self);
}

- (void)fulfillWith:(id)aResult
{
    if(!__sync_bool_compare_and_swap(&_result, _TQPromiseNotResolvedSentinel, aResult)) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"A promise can only be fulfilled once."
                                     userInfo:nil];
    } else
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
    return [(TQObject *)[self description] print];
}

- (NSString *)description
{
    if(_result != _TQPromiseNotResolvedSentinel)
        return [_result description];
    return [NSString stringWithFormat:@"<%@: %p (Unresolved)>", NSStringFromClass(object_getClass(self)), self];
}
@end
