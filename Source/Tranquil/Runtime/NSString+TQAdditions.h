#import <Foundation/Foundation.h>

@class TQNumber;

@interface NSString (Tranquil)
- (NSString *)stringByCapitalizingFirstLetter;
- (TQNumber *)toNumber;
- (NSMutableString *)multiply:(TQNumber *)aTimes;
- (NSMutableString *)add:(id)aObj;
- (char)charValue;
- (NSString *)trimmed;
@end

@interface NSMutableString (Tranquil)
- (NSMutableString *)trim;
@end
