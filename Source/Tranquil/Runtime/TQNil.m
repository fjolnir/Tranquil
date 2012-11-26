#import "TQNil.h"
#import "TQRuntime.h"
#import "TQNumber.h"
#import <objc/runtime.h>

const TQNil *TQGlobalNil;

static id nilReturner(id self, SEL sel, ...)
{
    return nil;
}

@implementation TQNil
+ (void)load
{
    TQGlobalNil = [class_createInstance(self, 0) init];
}

+ (id)_nil
{
    return TQGlobalNil;
}

+ (id)allocWithZone:(NSZone *)aZone
{
    return (TQNil*)TQGlobalNil;
}

- (id)init
{
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (oneway void)release {}
- (id)retain
{
    return self;
}

- (id)isNil
{
    return TQValid;
}
- (id)isIdenticalTo:(id)b
{
    return !b ? TQValid : nil;
}
- (id)isEqualTo:(id)b
{
    return !b ? TQValid : nil;
}
- (id)notEqualTo:(id)b
{
    return b ? TQValid : nil;
}
- (id)isLesserThan:(id)b
{
    return b ? TQValid : nil;
}
- (id)isLesserOrEqualTo:(id)b
{
    return TQValid;
}

- (void)dealloc
{
    [NSException raise:NSInternalInconsistencyException format:@"TQGlobalNil was deallocated!"];
    [super dealloc];
}

+ (BOOL)resolveInstanceMethod:(SEL)aSel
{
    NSMutableString *sig = [@"@:" mutableCopy];
    const char *selStr = sel_getName(aSel);
    for(int i = 0; i < strlen(selStr); ++i) {
        if(selStr[i] == ':')
            [sig appendString:@"@"];
    }
    class_addMethod(self, aSel, &nilReturner, [sig UTF8String]);
    [sig release];
    return YES;
}

- (BOOL)respondsToSelector:(SEL)selector
{
    return NO;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return NO;
}

- (NSUInteger)hash
{
    return 0;
}

- (BOOL)isEqual:(id)obj
{
    return !obj || obj == self || [obj isEqual:[NSNull null]];
}

- (BOOL)isKindOfClass:(Class)class
{
    return [class isEqual:[TQNil class]] || [class isEqual:[NSNull class]];
}

- (BOOL)isMemberOfClass:(Class)class
{
    return [class isEqual:[TQNil class]] || [class isEqual:[NSNull class]];
}

- (BOOL)isProxy
{
    return NO;
}

- (NSString *)description
{
    return nil;
}

- (Class)class
{
    return nil;
}

- (TQNumber *)add:(id)b      { return b;          }
- (TQNumber *)subtract:(id)b { return [b negate]; }

@end

