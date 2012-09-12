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
