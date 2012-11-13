#import "TQValidObject.h"

static TQValidObject *sharedInstance;

@implementation TQValidObject

+ (TQValidObject *)valid
{
    if(!sharedInstance)
        sharedInstance = [self new];
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
