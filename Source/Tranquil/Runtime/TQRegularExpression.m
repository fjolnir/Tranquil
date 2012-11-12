#import "TQRegularExpression.h"
#import "TQRuntime.h"
#import <objc/runtime.h>

@implementation TQRegularExpression
#if 0
+ (NSRegularExpression *)tq_regularExpressionWithPattern:(OFString *)aPattern options:(NSRegularExpressionOptions)aOpts
{
    TQError *err = nil;
    NSRegularExpression *regex = [self regularExpressionWithPattern:aPattern options:aOpts error:&err];
    if(err)
        TQLog(@"%@", err);
    return regex;
}

- (id)matches:(OFString *)aString
{
    OFArray *matches = [self matchesInString:aString options:0 range:(NSRange){0, [aString length]}];
    OFMutableArray *result = [OFMutableArray arrayWithCapacity:[matches count]];
    if([matches count] == 0)
        return nil;
    for(NSTextCheckingResult *match in matches) {
        [result addObject:[TQRange withNSRange:[match range]]];
    }
    return result;
}

- (id)match:(OFString *)aString usingBlock:(id (^)(OFString *text, TQRange *range))aBlock
{
    [self enumerateMatchesInString:aString
                           options:0
                             range:(NSRange){0, [aString length]}
                        usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        NSRange r = match.range;
        aBlock([aString substringWithRange:r], [TQRange withNSRange:r]);
    }];
    return nil;
}
#endif
@end

@implementation OFString (TQRegularExpression)
#if 0
- (id)matches:(TQRegularExpression *)aRegex
{
    return [aRegex matches:self];
}

- (id)match:(TQRegularExpression *)aRegex usingBlock:(id (^)(OFString *text, TQRange *range))aBlock
{
    return [aRegex match:self usingBlock:aBlock];
}
#endif
@end
