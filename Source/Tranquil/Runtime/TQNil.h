#import <Foundation/Foundation.h>

@class TQNil;

extern const TQNil * TQGlobalNil;

@interface TQNil : NSProxy
+ (id)_nil;
- (id)isNil;
@end
