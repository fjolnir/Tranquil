#import "TQObject.h"
#import "TQNumber.h"
#import "TQRuntime.h"
#import "OFString+TQAdditions.h"
#import <objc/runtime.h>

@implementation TQObject
+ (id)addMethod:(OFString *)aSel withBlock:(id)aBlock replaceExisting:(id)shouldReplace
{
    if(!aBlock) {
        TQLog(@"Tried to add nil block as method (%@)", aSel);
        return nil;
    }
    IMP imp = imp_implementationWithBlock(aBlock);
    OFMutableString *type = [OFMutableString stringWithString:@"@:"];
    const char *selCStr = [aSel UTF8String];
    for(int i = 0; i < [aSel length]; ++i) {
        if(selCStr[i] == ':')
            [type appendString:@"@"];
    }
    if(shouldReplace)
        class_replaceMethod(self, sel_registerName([aSel UTF8String]), imp, [type UTF8String]);
    else
        class_addMethod(self, sel_registerName([aSel UTF8String]), imp, [type UTF8String]);
    return TQValid;
}

+ (id)addMethod:(OFString *)aSel withBlock:(id)aBlock
{
    return [self addMethod:aSel withBlock:aBlock replaceExisting:TQValid];
}

+ (id)accessor:(OFString *)aPropName initialValue:(id<OFCopying>)aInitial
{
    [self addMethod:aPropName withBlock:^(id self_) {
        __block id ret = [TQGetDynamicIvarTable(self_) objectForKey:aPropName];
        if(!ret && aInitial) {
            @synchronized(self_) {
                ret = [aInitial copy];
                [TQGetDynamicIvarTable(self_) setObject:ret forKey:aPropName];
                [ret release];
            }
        }
        return ret;
    } replaceExisting:nil];
    OFString *setterSel = [OFString stringWithFormat:@"set%@:", [aPropName stringByCapitalizingFirstLetter]];
    [self addMethod:setterSel
          withBlock:^(id self_, id val) { [TQGetDynamicIvarTable(self_) setObject:val forKey:aPropName]; }
    replaceExisting:nil];

    return TQValid;
}

+ (id)accessor:(OFString *)aPropName
{
    return [self accessor:aPropName initialValue:nil];
}
@end
