#import <objc/runtime.h>
#import <Foundation/NSString.h>

// A minimal root class for use as parent of classes that do not need the functionality of NSObject
// Only implements the absolute minimal functionality required for receiving messages and logging to output

@interface TQRootObject
+ (void)initialize;
+ (Class)class;
- (Class)class;

+ (Class)superclass;
- (Class)superclass;

+ (BOOL)isSubclassOfClass:(Class)cls;

+ (BOOL)isMemberOfClass:(Class)cls;
- (BOOL)isMemberOfClass:(Class)cls;

+ (BOOL)isKindOfClass:(Class)cls;
- (BOOL)isKindOfClass:(Class)cls;

+ (NSString *)description;
- (NSString *)description;

+ (NSString *)debugDescription;
- (NSString *)debugDescription;

+ (void)doesNotRecognizeSelector:(SEL)sel;
- (void)doesNotRecognizeSelector:(SEL)sel;

+ (BOOL)respondsToSelector:(SEL)sel;
- (BOOL)respondsToSelector:(SEL)sel;
@end
