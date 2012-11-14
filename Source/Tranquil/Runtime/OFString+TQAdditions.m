#import "OFString+TQAdditions.h"
#import "TQNumber.h"
#import <string.h>

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

- (OFString *)pathExtension
{
    size_t loc = [self rangeOfString:@"." options:OF_STRING_SEARCH_BACKWARDS range:(of_range_t){0, [self length] }].location;
    return loc == OF_NOT_FOUND ? nil : [self substringFromIndex:loc+1];
}
- (OFString *)stringByDeletingPathExtension
{
    size_t loc = [self rangeOfString:@"." options:OF_STRING_SEARCH_BACKWARDS range:(of_range_t){0, [self length] }].location;
    return loc == OF_NOT_FOUND ? self : [self substringToIndex:loc];
}
- (OFString *)stringByAppendingPathExtension:(OFString *)ext
{
    OFMutableString *ret = [self mutableCopy];
    while([ret hasSuffix:@"/"])
        [ret deleteCharactersInRange:of_range([ret length]-1, 1)];
    [ret appendFormat:@".%@", ext];
    [ret makeImmutable];
    return ret;
}
- (const char *)fileSystemRepresentation
{
    return [self UTF8String];
}
- (BOOL)getFileSystemRepresentation:(char *)buffer maxLength:(unsigned long)maxLength
{
    strncpy(buffer, [self UTF8String], maxLength);
    return YES;
}
- (OFString *)stringByStandardizingPath
{
#warning "IMPLEMENT ME"
    return self;
}
@end

@implementation OFMutableString (Tranquil)
- (OFMutableString *)toString
{
    return self;
}
@end
