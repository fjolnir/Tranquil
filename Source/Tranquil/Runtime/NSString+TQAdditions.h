#import <Foundation/Foundation.h>

@class TQNumber;

@interface NSString (Tranquil)
- (NSString *)stringByCapitalizingFirstLetter;
- (TQNumber *)toNumber;
@end

@interface NSMutableString (Tranquil)
- (NSMutableString *)trim;
@end
