#import <Foundation/Foundation.h>
@interface NSBlock : NSObject
@end

@interface NSBlock (Tranquil)
- (id)if:(id)cond;
- (id)unless:(id)cond;
- (id)forever;
@end
