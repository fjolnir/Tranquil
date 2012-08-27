#import <Foundation/Foundation.h>
@class TQNumber;

@interface NSObject (Tranquil)
- (NSMutableString *)toString;
- (id)print;
+ (id)include:(Class)aClass recursive:(TQNumber *)aRecursive;
+ (id)include:(Class)aClass;
@end
