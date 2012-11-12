#import "TQValidObject.h"

static TQValidObject *sharedInstance;

@implementation TQValidObject
+ (void)load
{
    sharedInstance = [self new];
}

+ (TQValidObject *)valid
{
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

- (OFString *)description
{
    return @"Valid";
}
@end
