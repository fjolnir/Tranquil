#import <Foundation/Foundation.h>
@class TQNumber;

@interface NSObject (Tranquil)
- (id)isa:(Class)aClass;
- (id)isIdenticalTo:(id)obj;
- (id)isEqualTo:(id)b;
- (id)notEqualTo:(id)b;
- (id)isLesserThan:(id)b;
- (id)isGreaterThan:(id)b;
- (id)isLesserOrEqualTo:(id)b;
- (id)isGreaterOrEqualTo:(id)b;

- (NSMutableString *)toString;
- (id)print;
+ (id)include:(Class)aClass recursive:(id)aRecursive;
+ (id)include:(Class)aClass;
- (id)isNil;
@end
