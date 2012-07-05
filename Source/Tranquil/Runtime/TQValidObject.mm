#import "TQValidObject.h"

static TQValidObject *sharedInstance;

@implementation TQValidObject
+ (TQValidObject *)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}
@end
