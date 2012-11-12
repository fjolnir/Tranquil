#import <ObjFW/ObjFW.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface TQWeak : OFObject
+ (TQWeak *)with:(id)aObj;
@end
