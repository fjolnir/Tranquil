// A class whose instances simply represent a non-nil value. Corresponds to the 'valid' keyword
#import <Tranquil/Runtime/TQObject.h>


@interface TQValidObject : TQObject
+ (TQValidObject *)valid;
- (int)intValue;
- (BOOL)boolValue;
- (char)charValue;
@end
