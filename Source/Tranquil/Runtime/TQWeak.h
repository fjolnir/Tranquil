#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface TQWeak : NSProxy
+ (TQWeak *)with:(id)aObj;
@end
