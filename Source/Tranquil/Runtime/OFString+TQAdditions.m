#import "OFString+TQAdditions.h"
#import "TQNumber.h"

@implementation OFString (Tranquil)

- (OFString *)substringToIndex:(size_t)aIdx
{
    of_range_t range = { 0, aIdx };
    return [self substringWithRange:range];
}
- (OFString *)substringFromIndex:(size_t)aIdx
{
    of_range_t range = { aIdx, [self length] - aIdx };
    return [self substringWithRange:range];
}

- (OFString *)stringByCapitalizingFirstLetter
{
    unsigned long len = [self length];
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

- (OFMutableString *)multiply:(TQNumber *)aTimes
{
    OFMutableString *ret = [OFMutableString string];
    for(int i = 0; i < [aTimes intValue]; ++i) {
        [ret appendString:self];
    }
    return ret;
}

- (OFMutableString *)add:(id)aObj
{
    return [[[self stringByAppendingString:[aObj toString]] mutableCopy] autorelease];
}

- (OFMutableString *)toString
{
    return [[self mutableCopy] autorelease];
}

@end

@implementation OFMutableString (Tranquil)
- (OFMutableString *)toString
{
    return self;
}
@end
