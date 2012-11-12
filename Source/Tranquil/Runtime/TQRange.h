#import <Tranquil/Runtime/TQNumber.h>

@interface TQRange : TQObject
@property(readwrite, retain) TQNumber *start, *length;
+ (TQRange *)withLocation:(TQNumber *)aStart length:(TQNumber *)aLength;
+ (TQRange *)from:(TQNumber *)aStart to:(TQNumber *)aEnd;
- (id)each:(id (^)())aBlock;
@end
