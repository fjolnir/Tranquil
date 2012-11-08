#import "NSTask+TQAdditions.h"

#ifndef TARGET_OS_IPHONE
@implementation NSTask (Tranquil)
+ (NSString *)execute:(NSString *)aPath with:(NSArray *)aArguments;
{
    NSPipe *pipe = [NSPipe pipe];
    NSTask *task = [NSTask new];
    [task setLaunchPath:aPath];
    if([aArguments isKindOfClass:[NSArray class]] ||
       [aArguments isKindOfClass:[NSPointerArray class]]) {
        [task setArguments:aArguments];
    } else if([aArguments isKindOfClass:[NSString class]])
        [task setArguments:[NSArray arrayWithObject:aArguments]];
    [task setStandardOutput:pipe];
    [task setStandardError:[NSFileHandle fileHandleWithStandardError]];
    [task setStandardInput:[NSFileHandle fileHandleWithStandardInput]];
    [task launch];
    [task waitUntilExit];
    [task release];

    NSData *data = [[pipe fileHandleForReading] availableData];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
@end
#endif
