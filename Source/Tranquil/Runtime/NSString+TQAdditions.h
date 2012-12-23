#import <Foundation/Foundation.h>

@class TQNumber;

@interface NSString (Tranquil)
- (NSString *)stringByCapitalizingFirstLetter;
- (TQNumber *)toNumber;
- (NSMutableString *)multiply:(TQNumber *)aTimes;
- (NSMutableString *)add:(id)aObj;
- (char)charValue;
- (char)toChar;
- (NSString *)trimmed;
@end

@interface NSMutableString (Tranquil)
- (id)append:(NSString *)aString;
- (NSMutableString *)trim;
@end
