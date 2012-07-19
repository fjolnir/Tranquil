// A class whose instances simply represent a non-nil value. Corresponds to the 'valid' keyword
#import <Tranquil/TQObject.h>


@interface TQValidObject : TQObject
+ (TQValidObject *)sharedInstance;
- (int)intValue;
- (BOOL)boolValue;
- (char)charValue;
@end
