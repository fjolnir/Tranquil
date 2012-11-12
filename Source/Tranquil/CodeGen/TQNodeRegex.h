#import <Tranquil/CodeGen/TQNodeString.h>

@interface TQNodeRegex : TQNodeString
@property(readwrite, retain) OFMutableString *pattern;
@property(readwrite) int options; //NSRegularExpressionOptions options;
+ (TQNodeRegex *)nodeWithPattern:(OFString *)aPattern;
@end
