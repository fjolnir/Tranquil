// TODO: Find a replacement regular expression library
#import <ObjFW/ObjFW.h>
#import <Tranquil/Runtime/TQRange.h>

@interface TQRegularExpression : OFObject //NSRegularExpression
#if 0
+ (NSRegularExpression *)tq_regularExpressionWithPattern:(OFString *)aPattern options:(NSRegularExpressionOptions)aOpts;
#endif
@end

@interface OFString (TQRegularExpression)
#if 0
- (id)matches:(TQRegularExpression *)aRegex;
- (id)match:(TQRegularExpression *)aRegex usingBlock:(id (^)(OFString *text, TQRange *range))aBlock;
#endif
@end
