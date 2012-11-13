#import <ObjFW/ObjFW.h>

@interface OFObject (Tranquil)
+ (id)include:(Class)aClass;
@end

#ifdef __APPLE__
@interface NSObject
+ (Class)class;
- (NSString *)description;
- (BOOL)isKindOfClass:(Class)kls;
@end

@interface NSObject (Tranquil)
+ (id)include:(Class)aClass;
@end
#endif
