#import "TQModule.h"
#import "TQRuntime.h"

@implementation TQModule
+ (id)canBeIncludedInto:(Class)aClass
{
    return TQValid;
}

+ (id)allocWithZone:(NSZone *)aZone
{
    NSAssert(NO, @"Modules cannot be instantiated");
    return nil;
}
@end
