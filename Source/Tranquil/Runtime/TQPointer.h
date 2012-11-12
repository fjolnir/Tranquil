#import <Tranquil/Runtime/TQObject.h>

@class TQNumber;

extern OFString * const TQTypeObj;
extern OFString * const TQTypeClass;
extern OFString * const TQTypeSel;
extern OFString * const TQTypeChar;
extern OFString * const TQTypeUChar;
extern OFString * const TQTypeShort;
extern OFString * const TQTypeUShort;
extern OFString * const TQTypeInt;
extern OFString * const TQTypeUInt;
extern OFString * const TQTypeLong;
extern OFString * const TQTypeULong;
extern OFString * const TQTypeLongLong;
extern OFString * const TQTypeULongLong;
extern OFString * const TQTypeFloat;
extern OFString * const TQTypeDouble;
extern OFString * const TQTypeBool;
extern OFString * const TQTypeString;

// A class to enable use of (Obj-)C APIs that utilize pointers
@interface TQPointer : TQObject <OFCopying> {
    char *_itemType;
    unsigned long _itemSize, _count;
    BOOL _freeOnDealloc;
    @public
    char *_addr; // Only ever meant to be accessed by TQBoxedObject
}
+ (TQPointer *)box:(void *)aPtr withType:(const char *)aType;
+ (TQPointer *)withObjects:(OFArray *)aObjs type:(OFString *)aType;
+ (TQPointer *)to:(id)aObj withType:(OFString *)aType;
+ (TQPointer *)withType:(OFString *)aType count:(TQNumber *)aCount;
+ (TQPointer *)withType:(OFString *)aType;

- (id)initWithType:(const char *)aType count:(unsigned long)aCount;
- (id)initWithType:(const char *)aType address:(void *)aAddr count:(unsigned long)aCount;

- (TQPointer *)castTo:(OFString *)type;
- (id)addressAsObject;

- (id)objectAtIndexedSubscript:(unsigned long)aIdx;
- (void)setObject:(id)aObj atIndexedSubscript:(unsigned long)aIdx;

- (TQNumber *)count;
- (id)value; // Returns the first item
@end

@interface TQPointer (ConvenienceConstructors)
+ (TQPointer *)toObject;
+ (TQPointer *)toChar;
+ (TQPointer *)toBOOL;
+ (TQPointer *)toShort;
+ (TQPointer *)toInt;
+ (TQPointer *)toLong;
+ (TQPointer *)toLongLong;
+ (TQPointer *)toFloat;
+ (TQPointer *)toDouble;
+ (TQPointer *)toObjects:(TQNumber *)aCount;
+ (TQPointer *)toChars:(TQNumber *)aCount;
+ (TQPointer *)toBOOLs:(TQNumber *)aCount;
+ (TQPointer *)toShorts:(TQNumber *)aCount;
+ (TQPointer *)toInts:(TQNumber *)aCount;
+ (TQPointer *)toLongs:(TQNumber *)aCount;
+ (TQPointer *)toLongLongs:(TQNumber *)aCount;
+ (TQPointer *)toFloats:(TQNumber *)aCount;
+ (TQPointer *)toDoubles:(TQNumber *)aCount;
@end
