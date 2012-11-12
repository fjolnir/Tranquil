#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeString : TQNode
@property(readwrite, retain) OFMutableString *value;
@property(readwrite, retain) OFMutableArray *embeddedValues;
+ (TQNodeString *)nodeWithString:(OFMutableString *)aStr;
- (void)append:(OFString *)aStr;
@end

@interface TQNodeConstString : TQNodeString
+ (TQNodeConstString *)nodeWithString:(OFString *)aStr;
@end
