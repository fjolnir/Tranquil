#import "TQModule.h"
#import "TQRuntime.h"
#import <objc/runtime.h>

@implementation TQModule

+ (id)canBeIncludedInto:(Class)aClass
{
    return TQValid;
}

@end
