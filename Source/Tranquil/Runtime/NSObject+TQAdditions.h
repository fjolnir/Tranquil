#import <Foundation/Foundation.h>
@class TQNumber;

@interface NSObject (Tranquil)
- (id)isa:(Class)aClass;
- (id)isIdenticalTo:(id)obj;
- (NSMutableString *)toString;
- (id)print;
+ (id)include:(Class)aClass recursive:(id)aRecursive;
+ (id)include:(Class)aClass;
- (id)isNil;
@end
