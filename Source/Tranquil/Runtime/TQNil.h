#import <Tranquil/Runtime/TQObject.h>

@class TQNil;

extern const TQNil * TQGlobalNil;

@interface TQNil : TQObject
+ (id)_nil;
- (id)isNil;
@end
