#import <Tranquil/Runtime/TQNumber.h>

@interface TQRange : TQObject
@property(readwrite, retain) TQNumber *start, *length;
+ (TQRange *)withLocation:(TQNumber *)aStart length:(TQNumber *)aLength;
+ (TQRange *)from:(TQNumber *)aStart to:(TQNumber *)aEnd;
+ (TQRange *)withNSRange:(NSRange)aRange;
- (id)each:(id (^)())aBlock;
- (NSPointerArray *)toArray;
@end
