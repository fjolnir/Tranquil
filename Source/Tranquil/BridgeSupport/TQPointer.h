#import <Foundation/Foundation.h>

NSString * const TQTypeObj       = @"@";
NSString * const TQTypeClass     = @"#";
NSString * const TQTypeSel       = @":";
NSString * const TQTypeChar      = @"c";
NSString * const TQTypeUChar     = @"C";
NSString * const TQTypeShort     = @"s";
NSString * const TQTypeUShort    = @"S";
NSString * const TQTypeInt       = @"i";
NSString * const TQTypeUInt      = @"I";
NSString * const TQTypeLong      = @"l";
NSString * const TQTypeULong     = @"L";
NSString * const TQTypeLongLong  = @"q";
NSString * const TQTypeULongLong = @"Q";
NSString * const TQTypeFloat     = @"f";
NSString * const TQTypeDouble    = @"d";
NSString * const TQTypeBool      = @"B";
NSString * const TQTypeString    = @"*";

// A class to enable use of (Obj-)C APIs that utilize pointers
@interface TQPointer : NSObject {
    const char *_itemType;
    NSUInteger _itemSize, _count;
    BOOL _freeOnDealloc;
    @public
    char *_addr; // Only ever meant to be accessed by TQBoxedObject
}
+ (TQPointer *)withObjects:(NSArray *)aObjs type:(NSString *)aType;
+ (TQPointer *)to:(id)aObj withType:(NSString *)aType;
+ (TQPointer *)withType:(NSString *)aType count:(NSNumber *)aCount;
+ (TQPointer *)withType:(NSString *)aType;

- (id)initWithType:(const char *)aType count:(NSUInteger)aCount;
- (id)initWithType:(const char *)aType address:(void *)aAddr count:(NSUInteger)aCount;

- (id)objectAtIndexedSubscript:(NSUInteger)aIdx;
- (void)setObject:(id)aObj atIndexedSubscript:(NSUInteger)aIdx;
@end
