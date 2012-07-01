#import <Foundation/Foundation.h>

@interface NSNumber (TQOperators)
- (NSNumber *)add:(NSNumber *)b;
- (NSNumber *)subtract:(NSNumber *)b;
- (NSNumber *)negate;
- (NSNumber *)multiply:(NSNumber *)b;
- (NSNumber *)divide:(NSNumber *)b;
@end
