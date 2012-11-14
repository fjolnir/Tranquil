#import <Tranquil/Runtime/TQObject.h>

#ifdef DEBUG
    #define TQLog(fmt, ...) fputs([[OFString stringWithFormat:(OFConstantString *)[@"%@:%u (%s): " stringByAppendingFormat:@"%@\n", fmt], \
                              [[OFString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, \
                              __func__, ## __VA_ARGS__] UTF8String], stderr)

    #define TQLog_min(fmt, ...) fputs([[OFString stringWithFormat:fmt, __VA_ARGS__] UTF8String], stderr)

#define TQAssert(cond, fmt, ...) \
    do { \
        if(!(cond)) { \
            TQLog(@"Assertion failed: " fmt, ##__VA_ARGS__); \
            @throw [TQAssertException withReason:[OFString stringWithFormat:fmt, ##__VA_ARGS__]]; \
        } \
    } while(0)

    #define TQAssertSoft(cond, errDomain, errCode, retVal, fmt, ...) \
    do { \
        if(!(cond)) { \
            if(aoErr) { \
                OFString *desc = [OFString stringWithFormat:fmt, ##__VA_ARGS__]; \
                *aoErr = [TQError withDomain:(errDomain) code:(errCode) info:desc]; \
            } \
            TQLog(fmt, ##__VA_ARGS__); \
            return retVal; \
        } \
    } while(0)

#else
    #define TQLog(fmt, ...)
    #define TQAssert(cond, fmt, ...) cond
    #define TQAssertSoft(cond, errDomain, errCode, retVal, fmt, ...) cond
#endif

extern OFString * const kTQSyntaxErrorDomain;
extern OFString * const kTQGenericErrorDomain;
extern OFString * const kTQRuntimeErrorDomain;


typedef enum {
    kTQUnexpectedIdentifier = 1,
    kTQInvalidClassName,
    kTQInvalidAssignee,
    kTQUnexpectedStatement,
    kTQUnexpectedExpression,
    kTQObjCException,
    kTQGenericError
} TQSyntaxErrorCode;

@interface TQAssertException : OFException
@property(readonly, retain) OFString *reason;
+ (TQAssertException *)withReason:(OFString *)aReason;
@end

@interface TQError : TQObject
@property(readonly, retain) OFString *domain;
@property(readonly, retain) id info;
@property(readonly) long code;

+ (TQError *)withDomain:(OFString *)aDomain code:(long)aCode info:(id)aInfo;
@end

