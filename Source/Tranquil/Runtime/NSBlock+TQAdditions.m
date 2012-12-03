#import "NSBlock+TQAdditions.h"
#import "TQNumber.h"
#import <objc/runtime.h>

@implementation NSBlock (Tranquil)
- (id)if:(id)cond
{
    return cond ? TQDispatchBlock0(self) : nil;
}
- (id)unless:(id)cond
{
    return cond ? nil : TQDispatchBlock0(self);
}
- (id)forever
{
    while(true) TQDispatchBlock0(self);
}
@end
