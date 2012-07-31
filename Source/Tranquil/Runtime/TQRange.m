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

id TQDispatchBlock0(struct TQBlockLiteral *)      __asm("_TQDispatchBlock0");
id TQDispatchBlock1(struct TQBlockLiteral *, id ) __asm("_TQDispatchBlock1");
- (id)each:(id (^)())aBlock
{
    if(TQBlockGetNumberOfArguments(aBlock) == 1) {
        for(int i = 0; i < [_length intValue]; ++i) {
            TQDispatchBlock1((struct TQBlockLiteral *)aBlock, [TQNumber numberWithInt:i]);
        }
    } else {
        for(int i = 0; i < [_length intValue]; ++i) {
            TQDispatchBlock0((struct TQBlockLiteral *)aBlock);
        }
    }
    return nil;

    return nil;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p loc: %@ len: %@>", [self class], self, _start, _length];
}
@end

