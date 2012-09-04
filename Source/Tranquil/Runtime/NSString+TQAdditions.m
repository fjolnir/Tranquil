#import "NSString+TQAdditions.h"
#import "TQNumber.h"

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
- (TQNumber *)toNumber
{
    return [TQNumber numberWithDouble:atof([self UTF8String])];
}
@end

@implementation NSMutableString (Tranquil)
- (NSMutableString *)trim
{
    const char *chars = [self UTF8String];
    NSUInteger len    = [self length];
    NSUInteger startLen, endLen;
    for(startLen = 0; chars[startLen]         == ' ' && startLen < len; ++startLen);
    for(endLen   = 0; chars[len - endLen - 1] == ' ' && endLen < len;   ++endLen);
    if(startLen > 0)
        [self deleteCharactersInRange:(NSRange){ 0, startLen }];
    if(endLen > 0 && startLen != len)
        [self deleteCharactersInRange:(NSRange){ [self length] - endLen, endLen }];

    return self;
}
@end
