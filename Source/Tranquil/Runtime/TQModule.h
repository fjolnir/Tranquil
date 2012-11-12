#import <Tranquil/Runtime/TQObject.h>

@interface TQModule : TQObject
+ (id)canBeIncludedInto:(Class)aClass;
@end
