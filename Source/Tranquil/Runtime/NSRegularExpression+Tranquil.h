#import <Foundation/Foundation.h>


@interface NSRegularExpression (Tranquil)
+ (NSRegularExpression *)tq_regularExpressionWithUTF8String:(char *)aPattern options:(NSRegularExpressionOptions)aOpts;
@end


