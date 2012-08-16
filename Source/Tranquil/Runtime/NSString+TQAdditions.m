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

@implementation NSMutableString (Tranquil)
- (NSMutableString *)trim
{
    const char *chars = [self UTF8String];
    NSUInteger len = [self length];
    NSUInteger startLen, endLen;
    for(startLen = 0; chars[startLen] == ' ' && startLen < len; ++startLen);
    for(endLen = 0; chars[len - startLen - 1] == ' ' && endLen < len; ++endLen);
    if(startLen > 0)
        [self deleteCharactersInRange:(NSRange){ 0, startLen }];
    if(endLen > 0)
        [self deleteCharactersInRange:(NSRange){ len - endLen - 1, endLen }];

    return self;
}
@end
