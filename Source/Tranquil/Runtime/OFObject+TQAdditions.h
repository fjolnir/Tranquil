#import <ObjFW/ObjFW.h>

@interface OFObject (Tranquil)
- (id)isa:(Class)aClass;
- (id)isIdenticalTo:(id)obj;
- (OFMutableString *)toString;
- (id)print;
+ (id)include:(Class)aClass recursive:(id)aRecursive;
+ (id)include:(Class)aClass;
- (id)isNil;
@end
