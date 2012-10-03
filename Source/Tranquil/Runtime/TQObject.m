#import "TQObject.h"
#import "TQNumber.h"
#import "TQRuntime.h"
#import "NSString+TQAdditions.h"
#import <objc/runtime.h>

@implementation TQObject
+ (id)addMethod:(NSString *)aSel withBlock:(id)aBlock replaceExisting:(id)shouldReplace
{
    if(!aBlock) {
        TQLog(@"Tried to add nil block as method (%@)", aSel);
        return nil;
    }
    IMP imp = imp_implementationWithBlock(aBlock);
    NSMutableString *type = [NSMutableString stringWithString:@"@:"];
    const char *selCStr = [aSel UTF8String];
    for(int i = 0; i < [aSel length]; ++i) {
        if(selCStr[i] == ':')
            [type appendString:@"@"];
    }
    if(shouldReplace)
        class_replaceMethod(self, NSSelectorFromString(aSel), imp, [type UTF8String]);
    else
        class_addMethod(self, NSSelectorFromString(aSel), imp, [type UTF8String]);
    return TQValid;
}

+ (id)addMethod:(NSString *)aSel withBlock:(id)aBlock
{
    return [self addMethod:aSel withBlock:aBlock replaceExisting:TQValid];
}

+ (id)accessor:(NSString *)aPropName initialValue:(id<NSCopying>)aInitial
{
    [self addMethod:aPropName withBlock:^(id self_) {
        __block id ret = NSMapGet(TQGetDynamicIvarTable(self_), aPropName);
        if(!ret && aInitial) {
            @synchronized(self) {
                ret = [[aInitial copyWithZone:nil] autorelease];
                NSMapInsert(TQGetDynamicIvarTable(self_), aPropName, ret);
            }
        }
        return ret;
    } replaceExisting:nil];
    NSString *setterSel = [NSString stringWithFormat:@"set%@:", [aPropName stringByCapitalizingFirstLetter]];
    [self addMethod:setterSel withBlock:^(id self_, id val) { NSMapInsert(TQGetDynamicIvarTable(self_), aPropName, val); } replaceExisting:nil];

    return TQValid;
}

+ (id)accessor:(NSString *)aPropName
{
    return [self accessor:aPropName initialValue:nil];
}
@end
