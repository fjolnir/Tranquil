#import <Tranquil/Runtime/TQNumber.h>

@interface TQRange : TQObject
@property(readwrite, retain) TQNumber *start, *end, *step;
+ (TQRange *)withLocation:(TQNumber *)aStart length:(TQNumber *)aLength;
+ (TQRange *)from:(TQNumber *)aStart to:(TQNumber *)aEnd step:(TQNumber *)aStep;
+ (TQRange *)withNSRange:(NSRange)aRange;
- (id)each:(id (^)())aBlock;
@end
