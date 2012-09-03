#import <Foundation/Foundation.h>
@class TQNumber;

@interface NSObject (Tranquil)
- (id)isa:(Class)aClass;
- (NSMutableString *)toString;
- (id)print;
+ (id)include:(Class)aClass recursive:(TQNumber *)aRecursive;
+ (id)include:(Class)aClass;
- (id)isNil;
@end
