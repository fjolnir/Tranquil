#import "TQPointer.h"
#import "TQBoxedObject.h"
#import <objc/runtime.h>

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
    assert(aPtr);
    assert(*aType == _C_PTR || *aType == _C_ARY_B);
    NSUInteger count = NSNotFound;

    if(*aType++ == _C_ARY_B) {
        assert(isdigit(*aType));
        count = atoi(aType);
        // Move on to the enclosed type
        while(isdigit(*aType)) ++aType;
    }

    return [[[self alloc] initWithType:aType address:aPtr count:count] autorelease];
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

    _itemType      = aType;
    _addr          = (char *)aAddr;
    _freeOnDealloc = NO;
    _count         = aCount;
    NSGetSizeAndAlignment(_itemType, &_itemSize, NULL);
    assert(_itemSize > 0);

    return self;
}

- (id)init
{
    [NSException raise:@"Illegal Method" format:@"TQPointer can not be initialized without a type"];
    return nil;
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

- (void)dealloc
{
    if(_freeOnDealloc)
        free(_addr);
    [super dealloc];
}
@end
