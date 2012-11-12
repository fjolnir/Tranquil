#import "TQDebug.h"

OFString * const kTQSyntaxErrorDomain = @"org.tranquil.syntax";
OFString * const kTQRuntimeErrorDomain = @"org.tranquil.runtime";
OFString * const kTQGenericErrorDomain = @"org.tranquil.generic";

@implementation TQAssertException
+ (TQAssertException *)withReason:(OFString *)aReason
{
    TQAssertException *ret = [self new];
    ret->_reason = [aReason retain];
    return [ret autorelease];
}
- (void)dealloc
{
    [_reason release];
    [super dealloc];
}
@end

@implementation TQError
+ (TQError *)withDomain:(OFString *)aDomain code:(long)aCode info:(id)aInfo
{
    TQError *ret = [self new];
    ret->_domain = [aDomain retain];
    ret->_code   = aCode;
    ret->_info   = [aInfo retain];
    return [ret autorelease];
}

- (void)dealloc
{
    [_domain release];
    [_info release];
    [super dealloc];
}
@end
