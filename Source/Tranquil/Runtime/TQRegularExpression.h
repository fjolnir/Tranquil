#import <Foundation/Foundation.h>
#import <Tranquil/Runtime/TQRange.h>

@interface TQRegularExpression : NSRegularExpression
+ (NSRegularExpression *)tq_regularExpressionWithUTF8String:(char *)aPattern options:(NSRegularExpressionOptions)aOpts;
@end


