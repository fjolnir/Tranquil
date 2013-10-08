#import <Tranquil/Runtime/TQObject.h>

@class TQNumber;

extern NSString * const TQTypeObj;
extern NSString * const TQTypeClass;
extern NSString * const TQTypeSel;
extern NSString * const TQTypeChar;
extern NSString * const TQTypeUChar;
extern NSString * const TQTypeShort;
extern NSString * const TQTypeUShort;
extern NSString * const TQTypeInt;
extern NSString * const TQTypeUInt;
extern NSString * const TQTypeLong;
extern NSString * const TQTypeULong;
extern NSString * const TQTypeLongLong;
extern NSString * const TQTypeULongLong;
extern NSString * const TQTypeFloat;
extern NSString * const TQTypeDouble;
extern NSString * const TQTypeBool;
extern NSString * const TQTypeString;

// A class to enable use of (Obj-)C APIs that utilize pointers
@interface TQPointer : TQObject <NSCopying> {
    char *_itemType;
    NSUInteger _itemSize, _count;
    BOOL _freeOnDealloc;
    @public
    char *_addr; // Only ever meant to be accessed by TQBoxedObject
}
+ (TQPointer *)box:(void *)aPtr withType:(const char *)aType;
+ (TQPointer *)withObjects:(NSArray *)aObjs type:(NSString *)aType;
+ (TQPointer *)to:(id)aObj withType:(NSString *)aType;
+ (TQPointer *)withType:(NSString *)aType count:(NSNumber *)aCount;
+ (TQPointer *)withType:(NSString *)aType;

- (id)initWithType:(const char *)aType count:(NSUInteger)aCount;
- (id)initWithType:(const char *)aType address:(void *)aAddr count:(NSUInteger)aCount;

- (TQPointer *)castTo:(NSString *)type;
- (id)addressAsObject;

- (id)objectAtIndexedSubscript:(NSUInteger)aIdx;
- (void)setObject:(id)aObj atIndexedSubscript:(NSUInteger)aIdx;
- (id)at:(id)aIdx;
- (id)set:(id)aIdx to:(id)aVal;

- (TQNumber *)count;
- (id)value; // Returns the first item

- (const char *)UTF8String;

- (id)pointsToNULL;
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
+ (TQPointer *)toNSPoint;
+ (TQPointer *)toNSSize;
+ (TQPointer *)toNSRect;
+ (TQPointer *)toObjects:(TQNumber *)aCount;
+ (TQPointer *)toChars:(TQNumber *)aCount;
+ (TQPointer *)toBOOLs:(TQNumber *)aCount;
+ (TQPointer *)toShorts:(TQNumber *)aCount;
+ (TQPointer *)toInts:(TQNumber *)aCount;
+ (TQPointer *)toLongs:(TQNumber *)aCount;
+ (TQPointer *)toLongLongs:(TQNumber *)aCount;
+ (TQPointer *)toFloats:(TQNumber *)aCount;
+ (TQPointer *)toDoubles:(TQNumber *)aCount;
+ (TQPointer *)toNSPoints:(TQNumber *)aCount;
+ (TQPointer *)toNSSizes:(TQNumber *)aCount;
+ (TQPointer *)toNSRects:(TQNumber *)aCount;
@end
