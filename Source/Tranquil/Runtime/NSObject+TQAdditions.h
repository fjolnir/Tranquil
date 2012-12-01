#import <Foundation/Foundation.h>
@class TQNumber;

@interface NSObject (Tranquil)
+ (id)include:(Class)aClass recursive:(id)aRecursive;
+ (id)include:(Class)aClass;

- (NSMutableString *)toString;
- (id)print;
@end
