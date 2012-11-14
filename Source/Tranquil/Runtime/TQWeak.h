#import <Tranquil/Runtime/TQObject.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface TQWeak : TQObject
+ (TQWeak *)with:(id)aObj;
@end
