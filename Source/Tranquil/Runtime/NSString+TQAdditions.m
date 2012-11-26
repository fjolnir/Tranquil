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

- (char)charValue
{
    if([self length] == 0)
        return '\0';
    const char *str = [self UTF8String];
    return *str;
}

- (NSMutableString *)multiply:(TQNumber *)aTimes
{
    NSMutableString *ret = [NSMutableString string];
    for(int i = 0; i < [aTimes intValue]; ++i) {
        [ret appendString:self];
    }
    return ret;
}

- (NSString *)at:(id)aIdx
{
    return [self substringWithRange:(NSRange){[aIdx intValue], 1}];
}

- (NSMutableString *)add:(id)aObj
{
    return [[[self stringByAppendingString:[aObj toString]] mutableCopy] autorelease];
}

- (NSMutableString *)toString
{
    return [[self mutableCopy] autorelease];
}

- (NSString *)trimmed
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}
@end

@implementation NSMutableString (Tranquil)
- (NSMutableString *)trim
{
    [self setString:[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    return self;
}

- (NSMutableString *)toString
{
    return self;
}

- (NSString *)set:(NSString *)aReplacement at:(id)aIdx
{
    [self replaceCharactersInRange:(NSRange){ [aIdx unsignedIntegerValue], 1 } withString:aReplacement];
    return self;
}
@end
