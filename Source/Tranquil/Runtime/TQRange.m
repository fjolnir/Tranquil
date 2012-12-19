#import "TQRange.h"
#import "TQRuntime.h"
#import "../../../Build/TQStubs.h"
#import "TQEnumerable.h"
#import "NSObject+TQAdditions.h"

@implementation TQRange
@synthesize start=_start, end=_end, step=_step;
+ (void)load
{
    [self include:[TQEnumerable class]];
}
+ (TQRange *)withLocation:(TQNumber *)aStart length:(TQNumber *)aLength
{
    TQRange *ret = [self new];
    ret.start = aStart;
    ret.end   = [aStart add:aLength];
    return [ret autorelease];
}

+ (TQRange *)from:(TQNumber *)aStart to:(TQNumber *)aEnd step:(TQNumber *)aStep
{
    TQRange *ret = [self new];
    ret.start = aStart;
    ret.end   = aEnd;
    ret.step  = aStep;
    return [ret autorelease];
}

+ (TQRange *)withNSRange:(NSRange)aRange
{
    return [self withLocation:[TQNumber numberWithUnsignedInteger:aRange.location]
                       length:[TQNumber numberWithUnsignedInteger:aRange.length]];
}

- (id)each:(id (^)())aBlock
{
    // Integer fast path
    double start = [_start doubleValue];
    double end   = [_end doubleValue];
    double step  = _step ? [_step doubleValue] : 1.0;
    double unused;
    if(modf(start, &unused) <= DBL_EPSILON &&
       modf(end,   &unused) <= DBL_EPSILON &&
       modf(step,  &unused) <= DBL_EPSILON) {
        if(end >= start) {
            for(long i = start; i < (long)end; i += (long)step) {
                if(TQDispatchBlock1(aBlock, [TQNumber numberWithInt:i]) == TQNothing)
                    break;
            }
        } else {
            for(long i = start; i > (long)end; i += (long)step) {
                if(TQDispatchBlock1(aBlock, [TQNumber numberWithInt:i]) == TQNothing)
                    break;
            }
        }
    } else {
        if(end >= start) {
            for(double i = start; i < end; i += step) {
                if(TQDispatchBlock1(aBlock, [TQNumber numberWithDouble:i]) == TQNothing)
                    break;
            }
        } else {
            for(double i = start; i > end; i += step) {
                if(TQDispatchBlock1(aBlock, [TQNumber numberWithDouble:i]) == TQNothing)
                    break;
            }
        }
    }
    return nil;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p from: %@ to: %@>", [self class], self, _start, _end];
}
@end

