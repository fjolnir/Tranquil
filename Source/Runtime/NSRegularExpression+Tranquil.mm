#import "NSRegularExpression+Tranquil.h"
#import <objc/runtime.h>

@implementation NSRegularExpression (Tranquil)
+ (NSRegularExpression *)tq_regularExpressionWithUTF8String:(char *)aPattern options:(NSRegularExpressionOptions)aOpts
{
    NSString *str = [NSString stringWithUTF8String:aPattern];
    NSError *err = nil;
    NSRegularExpression *regex = [self regularExpressionWithPattern:str options:aOpts error:&err];
    if(err)
        NSLog(@"%@", err);
    return regex;
}
@end
