#import "TQRange.h"
#import "TQRuntime.h"

@implementation TQRange
@synthesize start=_start, length=_length;
+ (TQRange *)rangeWithLocation:(TQNumber *)aStart length:(TQNumber *)aLength
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
    ret.length = [aEnd subtract:aStart];
    return [ret autorelease];
}

extern id TQDispatchBlock0(id);
extern id TQDispatchBlock1(id, id);
extern id TQDispatchBlock2(id, id, id);

- (id)each:(id (^)())aBlock
{
    if(TQBlockGetNumberOfArguments(aBlock) == 1) {
        for(int i = 0; i < [_length intValue]; ++i) {
            TQDispatchBlock1(aBlock, [TQNumber numberWithInt:i]);
        }
    } else {
        for(int i = 0; i < [_length intValue]; ++i) {
            TQDispatchBlock0(aBlock);
        }
    }
    return nil;
}

- (id)reduce:(id (^)(id, id))aBlock
{
    id accum = TQSentinel; // Make the block use it's default accumulator on the first call
    for(int i = 0; i < [_length intValue]; ++i) {
        accum = TQDispatchBlock2(aBlock, [TQNumber numberWithInt:i], accum);
    }
    return accum;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p loc: %@ len: %@>", [self class], self, _start, _length];
}
@end

