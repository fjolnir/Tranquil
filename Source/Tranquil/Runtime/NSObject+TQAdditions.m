#import "NSObject+TQAdditions.h"

@implementation NSObject (Tranquil)
- (NSString *)toString
{
    return [[[self description] mutableCopy] autorelease];
}

- (id)print
{
    printf("%s\n", [[self description] UTF8String]);
    return self;
}
@end
