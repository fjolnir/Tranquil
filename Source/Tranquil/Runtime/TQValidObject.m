#import "TQValidObject.h"

static TQValidObject *sharedInstance;

@implementation TQValidObject
+ (TQValidObject *)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (int)intValue
{
    return 1;
}

- (BOOL)boolValue
{
    return YES;
}

- (char)charValue
{
    return 1;
}

- (NSString *)description
{
    return @"Valid";
}
@end
