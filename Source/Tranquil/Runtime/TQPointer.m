#import "TQPointer.h"
#import "TQBoxedObject.h"
#import "TQRuntime.h"
#import "TQNumber.h"
#import <objc/runtime.h>

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

@implementation TQPointer

+ (void)load
{
    if(self != [TQPointer class])
        return;
    IMP imp;
    imp = imp_implementationWithBlock(^(id a, id idx)   {
        return objc_msgSend(a, @selector(objectAtIndexedSubscript:), [idx unsignedIntegerValue]);
    });
    class_addMethod(self, sel_registerName("[]:"), imp, "@@:@");
    // []=
    imp = imp_implementationWithBlock(^(id a, id idx, id val)   {
        return objc_msgSend(a, @selector(setObject:atIndexedSubscript:), val, [idx unsignedIntegerValue]);
    });
    class_addMethod(self, sel_registerName("[]:=:"), imp, "@@:@@");
}

+ (TQPointer *)box:(void *)aPtr withType:(const char *)aType
{
    if(!aPtr)
        return nil;
    TQAssert(*aType == _C_PTR || *aType == _C_ARY_B, @"Tried to create a pointer using a non-pointer type");
    NSUInteger count = 1;

    if(*aType++ == _C_ARY_B) {
        assert(isdigit(*aType));
        count = atoi(aType);
        // Move on to the enclosed type
        while(isdigit(*aType)) ++aType;
    }
    return [[[self alloc] initWithType:aType address:*(void**)aPtr count:count] autorelease];
}

+ (TQPointer *)withObjects:(NSArray *)aObjs type:(NSString *)aType
{
    NSUInteger count = [aObjs count];
    TQPointer *ptr = [self withType:aType count:[NSNumber numberWithUnsignedInteger:count]];
    for(int i = 0; i < count; ++i) {
        [ptr setObject:[aObjs objectAtIndex:i] atIndexedSubscript:i];
    }
    return ptr;
}

+ (TQPointer *)to:(id)aObj withType:(NSString *)aType
{
    TQPointer *ptr = [self withType:aType count:[NSNumber numberWithUnsignedInteger:1]];
    [ptr setObject:aObj atIndexedSubscript:0];
    return ptr;
}
+ (TQPointer *)withType:(NSString *)aType count:(NSNumber *)aCount
{
    return [[[self alloc] initWithType:[aType UTF8String] count:[aCount unsignedIntegerValue]] autorelease];
}
+ (TQPointer *)withType:(NSString *)aType
{
    return [self withType:aType count:[NSNumber numberWithUnsignedInteger:1]];
}

- (id)initWithType:(const char *)aType count:(NSUInteger)aCount
{
    if(!(self = [self initWithType:aType address:NULL count:aCount]))
        return nil;

    _addr = (char *)calloc(_count, _itemSize);
    _freeOnDealloc = YES;

    return self;
}

- (id)initWithType:(const char *)aType address:(void *)aAddr count:(NSUInteger)aCount
{
    if(!(self = [super init]))
        return nil;

    assert(aType != nil);
    assert(aCount > 0);

    _itemType      = strdup(aType);
    _addr          = (char *)aAddr;
    _freeOnDealloc = NO;
    _count         = aCount;
    TQGetSizeAndAlignment(_itemType, &_itemSize, NULL);
    if(_itemSize == 0) {
        free(_itemType);
        _itemType = strdup("v");
        _itemSize = sizeof(void*);
    }

    return self;
}

- (id)init
{
    [NSException raise:@"Illegal Method" format:@"TQPointer can not be initialized without a type"];
    return nil;
}
- (id)_init
{
    return [super init];
}

- (id)copyWithZone:(NSZone *)zone
{
    TQPointer *ret = [[[self class] alloc] _init];
    ret->_itemType = _itemType;
    ret->_itemSize = _itemSize;
    ret->_count    = _count;
    ret->_freeOnDealloc = _freeOnDealloc;
    if(ret->_freeOnDealloc) {
        ret->_addr = malloc(_count*_itemSize);
        memcpy(ret->_addr, _addr, _count*_itemSize);
    } else
        ret->_addr = ret->_addr;
    return ret;
}

- (id)castTo:(NSString *)type
{
    NSUInteger size;
    TQGetSizeAndAlignment([type UTF8String], &size, NULL);
    TQAssert(size == _itemSize, @"Tried to cast pointer to a type of a different size");
    TQPointer *ret = [self copy];
    ret->_itemType = strdup([type UTF8String]);
    return [ret autorelease];
}

- (id)addressAsObject
{
    return (id)_addr;
}

- (TQNumber *)count
{
    return [TQNumber numberWithInt:_count];
}

- (void *)_addrForIndex:(NSUInteger)aIdx
{
   if(aIdx >= _count)
        [NSException raise:NSRangeException format:@"Index %ld is out of bounds (%ld)", aIdx, _count];
    return _addr + (aIdx * _itemSize);
}

- (id)objectAtIndexedSubscript:(NSUInteger)aIdx {
    return [TQBoxedObject box:[self _addrForIndex:aIdx] withType:_itemType];
}

- (void)setObject:(id)aObj atIndexedSubscript:(NSUInteger)aIdx
{
    [TQBoxedObject unbox:aObj to:[self _addrForIndex:aIdx] usingType:_itemType];
}

- (id)value
{
    return [self objectAtIndexedSubscript:0];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p to: %p type: %s>", [self class], self, _addr, _itemType];
}

- (id)print
{
    if(*_itemType == _C_CHARPTR)
        printf("%s", _addr);
    else if(*_itemType == _C_CHR)
        fwrite(_addr, sizeof(char), _count, stdout);
    else
        printf("%s\n", [[self description] UTF8String]);
    return nil;
}

- (NSMutableString *)toString
{
    const char *cStr = [self UTF8String];
    if(cStr)
        return [NSMutableString stringWithUTF8String:cStr];
    return nil;
}

- (const char *)UTF8String
{
    return *_itemType == _C_CHARPTR ? _addr : NULL;
}

- (void)dealloc
{
    if(_freeOnDealloc)
        free(_addr);
    free(_itemType);
    [super dealloc];
}
@end

@implementation TQPointer (ConvenienceConstructors)
+ (TQPointer *)toObjects:(TQNumber *)aCount
{
    return [[[self alloc] initWithType:@encode(id) count:[aCount unsignedIntegerValue]] autorelease];
}
+ (TQPointer *)toVoids:(TQNumber *)aCount
{
    return [[[self alloc] initWithType:@encode(void) count:[aCount unsignedIntegerValue]] autorelease];
}
+ (TQPointer *)toChars:(TQNumber *)aCount
{
    return [[[self alloc] initWithType:@encode(char) count:[aCount unsignedIntegerValue]] autorelease];
}
+ (TQPointer *)toBOOLs:(TQNumber *)aCount
{
    return [[[self alloc] initWithType:@encode(BOOL) count:[aCount unsignedIntegerValue]] autorelease];
}
+ (TQPointer *)toShorts:(TQNumber *)aCount
{
    return [[[self alloc] initWithType:@encode(short) count:[aCount unsignedIntegerValue]] autorelease];
}
+ (TQPointer *)toInts:(TQNumber *)aCount
{
    return [[[self alloc] initWithType:@encode(int) count:[aCount unsignedIntegerValue]] autorelease];
}
+ (TQPointer *)toLongs:(TQNumber *)aCount
{
    return [[[self alloc] initWithType:@encode(long) count:[aCount unsignedIntegerValue]] autorelease];
}
+ (TQPointer *)toLongLongs:(TQNumber *)aCount
{
    return [[[self alloc] initWithType:@encode(long long) count:[aCount unsignedIntegerValue]] autorelease];
}
+ (TQPointer *)toFloats:(TQNumber *)aCount
{
    return [[[self alloc] initWithType:@encode(float) count:[aCount unsignedIntegerValue]] autorelease];
}
+ (TQPointer *)toDoubles:(TQNumber *)aCount
{
    return [[[self alloc] initWithType:@encode(double) count:[aCount unsignedIntegerValue]] autorelease];
}
+ (TQPointer *)toNSPoints:(TQNumber *)aCount
{
    return [[[self alloc] initWithType:@encode(NSPoint) count:[aCount unsignedIntegerValue]] autorelease];
}
+ (TQPointer *)toNSSizes:(TQNumber *)aCount
{
    return [[[self alloc] initWithType:@encode(NSSize) count:[aCount unsignedIntegerValue]] autorelease];
}
+ (TQPointer *)toNSRects:(TQNumber *)aCount
{
    return [[[self alloc] initWithType:@encode(NSRect) count:[aCount unsignedIntegerValue]] autorelease];
}
+ (TQPointer *)toObject
{
    return [self toObjects:[TQNumber numberWithInt:1]];
}
+ (TQPointer *)toChar
{
    return [self toChars:[TQNumber numberWithInt:1]];
}
+ (TQPointer *)toVoid
{
    return [self toVoids:[TQNumber numberWithInt:1]];
}
+ (TQPointer *)toBOOL
{
    return [self toBOOLs:[TQNumber numberWithInt:1]];
}
+ (TQPointer *)toShort
{
    return [self toShorts:[TQNumber numberWithInt:1]];
}
+ (TQPointer *)toInt
{
    return [self toInts:[TQNumber numberWithInt:1]];
}
+ (TQPointer *)toLong
{
    return [self toLongs:[TQNumber numberWithInt:1]];
}
+ (TQPointer *)toLongLong
{
    return [self toLongLongs:[TQNumber numberWithInt:1]];
}
+ (TQPointer *)toFloat
{
    return [self toFloats:[TQNumber numberWithInt:1]];
}
+ (TQPointer *)toDouble
{
    return [self toDoubles:[TQNumber numberWithInt:1]];
}
+ (TQPointer *)toNSPoint
{
    return [self toNSPoints:[TQNumber numberWithInt:1]];
}
+ (TQPointer *)toNSSize
{
    return [self toNSSizes:[TQNumber numberWithInt:1]];
}
+ (TQPointer *)toNSRect
{
    return [self toNSRects:[TQNumber numberWithInt:1]];
}
@end
