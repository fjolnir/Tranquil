#import "TQNil.h"
#import "TQRuntime.h"
#import <objc/runtime.h>

const TQNil *TQGlobalNil;

static id nilReturner(id self, SEL sel, ...)
{
    return nil;
}

@implementation TQNil
+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        TQGlobalNil = [class_createInstance(self, 0) init];
    });
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

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    NSUInteger returnLength = [[anInvocation methodSignature] methodReturnLength];
    if(returnLength == 0)
        return;

    // Set return value to all zero bits
    char buffer[returnLength];
    memset(buffer, 0, returnLength);

    [anInvocation setReturnValue:buffer];
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
@end

