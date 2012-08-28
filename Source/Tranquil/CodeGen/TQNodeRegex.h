#import <Tranquil/CodeGen/TQNodeString.h>

@interface TQNodeRegex : TQNodeString
@property(readwrite, retain) NSMutableString *pattern;
@property(readwrite) NSRegularExpressionOptions options;
+ (TQNodeRegex *)nodeWithPattern:(NSString *)aPattern;
@end
