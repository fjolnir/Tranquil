#import "NSString+TQAdditions.h"

@implementation NSString (Tranquil)
- (NSString *)stringByCapitalizingFirstLetter
{
    NSUInteger len = [self length];
    if(len == 0)
        return self;
    else if(len == 1)
        return [self uppercaseString];
    return [[[self substringToIndex:1] uppercaseString] stringByAppendingString:[self substringFromIndex:1]];
}
@end
