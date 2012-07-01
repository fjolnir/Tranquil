#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeRegex : TQNode
@property(readwrite, retain) NSString *pattern;
+ (TQNodeRegex *)nodeWithPattern:(NSString *)aPattern;
@end
