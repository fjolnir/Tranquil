// Note: TQNumber is not safe to subclass. It makes certain assumptions for the sake of performance
// Currently numbers are always stored as doubles, need to add handling of integers(long, int, short, char) that doesn't mess up their data layout

#import <Foundation/Foundation.h>
#import <Tranquil/TQObject.h>
#import <Tranquil/TQBatching.h>

@class TQRange;

@interface TQNumber : TQObject {
    @public
    double _value;
    TQ_BATCH_IVARS
}
@property(readonly) double value;

- (id)initWithBool:(BOOL)value;
- (id)initWithChar:(char)value;
- (id)initWithShort:(short)value;
- (id)initWithInt:(int)value;
- (id)initWithLong:(long)value;
- (id)initWithLongLong:(long long)value;
- (id)initWithFloat:(float)value;
- (id)initWithDouble:(double)value;
- (id)initWithInteger:(NSInteger)value;

- (id)initWithUnsignedChar:(unsigned char)value;
- (id)initWithUnsignedShort:(unsigned short)value;
- (id)initWithUnsignedInt:(unsigned int)value;
- (id)initWithUnsignedLong:(unsigned long)value;
- (id)initWithUnsignedLongLong:(unsigned long long)value;
- (id)initWithUnsignedInteger:(NSUInteger)value;

+ (TQNumber *)numberWithBool:(BOOL)value;
+ (TQNumber *)numberWithChar:(char)value;
+ (TQNumber *)numberWithShort:(short)value;
+ (TQNumber *)numberWithInt:(int)value;
+ (TQNumber *)numberWithLong:(long)value;
+ (TQNumber *)numberWithLongLong:(long long)value;
+ (TQNumber *)numberWithFloat:(float)value;
+ (TQNumber *)numberWithDouble:(double)value;
+ (TQNumber *)numberWithInteger:(NSInteger)value;

+ (NSNumber *)numberWithUnsignedChar:(unsigned char)value;
+ (NSNumber *)numberWithUnsignedShort:(unsigned short)value;
+ (NSNumber *)numberWithUnsignedInt:(unsigned int)value;
+ (NSNumber *)numberWithUnsignedLong:(unsigned long)value;
+ (NSNumber *)numberWithUnsignedLongLong:(unsigned long long)value;
+ (NSNumber *)numberWithUnsignedInteger:(NSUInteger)value;

- (char)charValue;
- (short)shortValue;
- (int)intValue;
- (long)longValue;
- (long long)longLongValue;
- (float)floatValue;
- (double)doubleValue;
- (BOOL)boolValue;
- (NSInteger)integerValue;

- (unsigned char)unsignedCharValue;
- (unsigned short)unsignedShortValue;
- (unsigned int)unsignedIntValue;
- (unsigned long)unsignedLongValue;
- (unsigned long long)unsignedLongLongValue;
- (NSUInteger)unsignedIntegerValue;

- (TQNumber *)add:(id)b;
- (TQNumber *)subtract:(id)b;
- (TQNumber *)negate;
- (TQNumber *)ceil;
- (TQNumber *)floor;
- (TQNumber *)multiply:(id)b;
- (TQNumber *)divideBy:(id)b;
- (TQNumber *)modulo:(id)b;
- (TQNumber *)pow:(id)b;

- (TQNumber *)bitAnd:(id)b;
- (TQNumber *)bitOr:(id)b;
- (TQNumber *)xor:(id)b;
- (TQNumber *)lshift:(id)b;
- (TQNumber *)rshift:(id)b;

- (TQRange *)to:(TQNumber *)b;
- (id)times:(id (^)())block;
@end
