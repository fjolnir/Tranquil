#import "TQRegularExpression.h"
#import "TQRuntime.h"
#import <objc/runtime.h>

@implementation TQRegularExpression
+ (NSRegularExpression *)tq_regularExpressionWithUTF8String:(char *)aPattern options:(NSRegularExpressionOptions)aOpts
{
    NSString *str = [NSString stringWithUTF8String:aPattern];
    NSError *err = nil;
    NSRegularExpression *regex = [self regularExpressionWithPattern:str options:aOpts error:&err];
    if(err)
        NSLog(@"%@", err);
    return regex;
}

- (id)matches:(NSString *)aString
{
    return [self numberOfMatchesInString:aString options:0 range:(NSRange){0, [aString length]}] > 0 ? TQValid : nil;
}

- (id)match:(NSString *)aString usingBlock:(id (^)(NSString *text, TQRange *range))aBlock
{
    [self enumerateMatchesInString:aString
                           options:0
                             range:(NSRange){0, [aString length]}
                        usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        NSRange r = match.range;
        aBlock([aString substringWithRange:r],
               [TQRange rangeWithLocation:[TQNumber numberWithInt:r.location] length:[TQNumber numberWithInt:r.length]]);
    }];
    return nil;
}
@end
