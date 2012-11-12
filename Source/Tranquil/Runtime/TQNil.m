#import "TQNil.h"
#import "TQRuntime.h"
#import "TQNumber.h"
#import <objc/runtime.h>
#import <string.h>

const TQNil *TQGlobalNil;

static id nilReturner(id self, SEL sel, ...)
{
    return nil;
}

@implementation TQNil

+ (void)load
{
    if(self != [TQNil class])
        return;

    TQGlobalNil = [class_createInstance(self, 0) init];
    class_replaceMethod(self, TQAddOpSel, class_getMethodImplementation(self, @selector(add:)),      "@@:@");
    class_replaceMethod(self, TQSubOpSel, class_getMethodImplementation(self, @selector(subtract:)), "@@:@");
}

+ (id)_nil
{
    return TQGlobalNil;
}

+ (id)alloc
{
    return (TQNil*)TQGlobalNil;
}

- (id)init
{
    return self;
}

- (id)copy
{
    return self;
}

- (void)release {}
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
    OFMutableString *sig = [@"@:" mutableCopy];
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

- (uint32_t)hash
{
    return 0;
}

- (BOOL)isEqual:(id)obj
{
    return !obj || obj == self;
}

- (BOOL)isKindOfClass:(Class)class
{
    return [class isEqual:[TQNil class]];
}

- (BOOL)isMemberOfClass:(Class)class
{
    return [class isEqual:[TQNil class]];
}

- (OFString *)description
{
    return nil;
}

- (Class)class
{
    return nil;
}

- (TQNumber *)add:(id)b      { return [[TQNumber numberWithInt:0] add:b];      }
- (TQNumber *)subtract:(id)b { return [[TQNumber numberWithInt:0] subtract:b]; }

@end

