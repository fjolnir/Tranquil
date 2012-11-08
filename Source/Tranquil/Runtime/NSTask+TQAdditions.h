#import <Foundation/Foundation.h>

#if !TARGET_OS_IPHONE
@interface NSTask (Tranquil)
+ (NSString *)execute:(NSString *)aPath with:(NSArray *)aArguments;
@end
#endif
