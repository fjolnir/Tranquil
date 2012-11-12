// Note: TQNumber is not safe to subclass. It makes certain assumptions for the sake of performance
// Currently numbers are always stored in floating point, need to add handling of integers(long, int, short, char) that guarantees their data layout is not messed up

#import <ObjFW/ObjFW.h>
#import <Tranquil/Runtime/TQObject.h>
#import <Tranquil/Shared/TQBatching.h>

@class TQRange;

// The tag used to create tagged pointer TQNumbers (Tag is in the least significant byte)
extern const unsigned char kTQNumberTagSlot;    // The tag as an integer
extern const uintptr_t     kTQNumberTag;        // The actual bits of the tag (use inverted to get the value of a tagged number)

BOOL TQFloatFitsInTaggedNumber(float aValue);

@interface TQNumber : TQObject {
    @public
    double _value;
    TQ_BATCH_IVARS
}
@property(readonly) double value;

+ (id)fitsInTaggedPointer:(double)aValue;

- (id)initWithBool:(BOOL)value;
- (id)initWithChar:(char)value;
- (id)initWithShort:(short)value;
- (id)initWithInt:(int)value;
- (id)initWithLong:(long)value;
- (id)initWithLongLong:(long long)value;
- (id)initWithFloat:(float)value;
- (id)initWithDouble:(double)value;
- (id)initWithInteger:(long)value;

- (id)initWithUnsignedChar:(unsigned char)value;
- (id)initWithUnsignedShort:(unsigned short)value;
- (id)initWithUnsignedInt:(unsigned int)value;
- (id)initWithUnsignedLong:(unsigned long)value;
- (id)initWithUnsignedLongLong:(unsigned long long)value;
- (id)initWithUnsignedInteger:(unsigned long)value;

+ (TQNumber *)numberWithBool:(BOOL)value;
+ (TQNumber *)numberWithChar:(char)value;
+ (TQNumber *)numberWithShort:(short)value;
+ (TQNumber *)numberWithInt:(int)value;
+ (TQNumber *)numberWithLong:(long)value;
+ (TQNumber *)numberWithLongLong:(long long)value;
+ (TQNumber *)numberWithFloat:(float)value;
+ (TQNumber *)numberWithDouble:(double)value;
+ (TQNumber *)numberWithInteger:(long)value;

+ (TQNumber *)numberWithUnsignedChar:(unsigned char)value;
+ (TQNumber *)numberWithUnsignedShort:(unsigned short)value;
+ (TQNumber *)numberWithUnsignedInt:(unsigned int)value;
+ (TQNumber *)numberWithUnsignedLong:(unsigned long)value;
+ (TQNumber *)numberWithUnsignedLongLong:(unsigned long long)value;
+ (TQNumber *)numberWithUnsignedInteger:(unsigned long)value;

- (char)charValue;
- (short)shortValue;
- (int)intValue;
- (long)longValue;
- (long long)longLongValue;
- (float)floatValue;
- (double)doubleValue;
- (BOOL)boolValue;
- (long)integerValue;

- (unsigned char)unsignedCharValue;
- (unsigned short)unsignedShortValue;
- (unsigned int)unsignedIntValue;
- (unsigned long)unsignedLongValue;
- (unsigned long long)unsignedLongLongValue;
- (unsigned long)unsignedIntegerValue;

- (id)add:(id)b;
- (id)subtract:(id)b;
- (id)negate;
- (id)multiply:(id)b;
- (id)divideBy:(id)b;
- (id)pow:(id)b;
- (TQNumber *)ceil;
- (TQNumber *)floor;
- (TQNumber *)modulo:(id)b;
- (TQNumber *)sqrt;
- (TQNumber *)log:(TQNumber *)base;
- (TQNumber *)log;
- (TQNumber *)log2;
- (TQNumber *)ln;

- (TQNumber *)sine;
- (TQNumber *)cosine;
- (TQNumber *)tan;
- (TQNumber *)hsine;
- (TQNumber *)hcosine;
- (TQNumber *)htan;
- (TQNumber *)arcsine;
- (TQNumber *)arcosine;
- (TQNumber *)arctan;

- (TQNumber *)bitAnd:(id)b;
- (TQNumber *)bitOr:(id)b;
- (TQNumber *)xor:(id)b;
- (TQNumber *)lshift:(id)b;
- (TQNumber *)rshift:(id)b;

- (id)isGreater:(id)b;
- (id)isLesser:(id)b;
- (id)isGreaterOrEqual:(id)b;
- (id)isLesserOrEqual:(id)b;

- (TQRange *)to:(TQNumber *)b;
- (id)times:(id (^)())block;
@end
