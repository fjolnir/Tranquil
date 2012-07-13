#import <Foundation/Foundation.h>

typedef id (^condBlock)();
@interface NSNumber (TQOperators)
- (NSNumber *)add:(id)b;
- (NSNumber *)subtract:(id)b;
- (NSNumber *)negate;
- (NSNumber *)multiply:(id)b;
- (NSNumber *)divide:(id)b;
@end
