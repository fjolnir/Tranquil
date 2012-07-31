#import <Foundation/Foundation.h>
#import <Tranquil/Runtime/TQRange.h>

@interface TQRegularExpression : NSRegularExpression
+ (NSRegularExpression *)tq_regularExpressionWithUTF8String:(char *)aPattern options:(NSRegularExpressionOptions)aOpts;
@end

@interface NSString (TQRegularExpression)
- (id)matches:(TQRegularExpression *)aRegex;
- (id)match:(TQRegularExpression *)aRegex usingBlock:(id (^)(NSString *text, TQRange *range))aBlock;
@end
