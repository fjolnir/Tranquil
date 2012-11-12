#import "TQRange.h"
#import "TQRuntime.h"
#import "../../../Build/TQStubs.h"
#import "TQEnumerable.h"

@implementation TQRange
@synthesize start=_start, length=_length;
+ (void)load
{
    [self include:[TQEnumerable class]];
}
+ (TQRange *)withLocation:(TQNumber *)aStart length:(TQNumber *)aLength
{
    TQRange *ret = [self new];
    ret.start  = aStart;
    ret.length = aLength;
    return [ret autorelease];
}

+ (TQRange *)from:(TQNumber *)aStart to:(TQNumber *)aEnd
{
    TQRange *ret = [self new];
    ret.start  = aStart;
    ret.length = [TQNumber numberWithInt:[aEnd intValue] - [aStart intValue] + 1];
    return [ret autorelease];
}

- (id)each:(id (^)())aBlock
{
    long start = [_start intValue];
    long end   = start + [_length intValue];
    if(end >= start) {
        for(int i = start; i < end; ++i) {
            if(TQDispatchBlock1(aBlock, [TQNumber numberWithInt:i]) == TQNothing)
                break;
        }
    } else {
        for(int i = start; i > end; --i) {
            if(TQDispatchBlock1(aBlock, [TQNumber numberWithInt:i]) == TQNothing)
                break;

        }
    }
    return nil;
}

- (OFString *)description
{
    return [OFString stringWithFormat:@"<%@: %p loc: %@ len: %@>", [self class], self, _start, _length];
}
@end

