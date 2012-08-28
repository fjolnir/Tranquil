#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeString : TQNode
@property(readwrite, retain) NSMutableString *value;
@property(readwrite, retain) NSMutableArray *embeddedValues;
+ (TQNodeString *)nodeWithString:(NSMutableString *)aStr;
- (void)append:(NSString *)aStr;
@end

@interface TQNodeConstString : TQNodeString
+ (TQNodeConstString *)nodeWithString:(NSString *)aStr;
@end
