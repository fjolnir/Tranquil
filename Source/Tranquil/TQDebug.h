#import <Foundation/Foundation.h>

#ifdef DEBUG
    #define TQLog(fmt, ...) NSLog(@"%s:%u (%s): " fmt "\n", __FILE__, __LINE__, __func__, ## __VA_ARGS__)
    #define TQLog_min(fmt, ...)  NSLog(fmt "\n", ## __VA_ARGS__)


#define TQAssert(cond, fmt, ...) \
    do { \
        if(!(cond)) { \
            TQLog(@"Assertion failed: " fmt, ##__VA_ARGS__); \
            exit(1); \
        } \
    } while(0)

    #define TQAssertSoft(cond, errDomain, errCode, retVal, fmt, ...) \
    do { \
        if(!(cond)) { \
            if(aoError) { \
                NSString *errorDesc = [NSString stringWithFormat:fmt, ##__VA_ARGS__]; \
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorDesc \
                                                                     forKey:NSLocalizedDescriptionKey]; \
                *aoError = [NSError errorWithDomain:(errDomain) code:(errCode) userInfo:userInfo]; \
            } \
            TQLog(fmt, ##__VA_ARGS__); \
            return retVal; \
        } \
    } while(0)

#else
    #define TQLog(fmt, ...)
    #define TQAssert(cond, fmt, ...)
#endif

extern NSString * const kTQSyntaxErrorDomain;
extern NSString * const kTQGenericErrorDomain;


typedef enum {
    kTQUnexpectedIdentifier = 1,
    kTQInvalidClassName,
    kTQInvalidAssignee,
    kTQUnexpectedStatement,
    kTQGenericError
} TQSyntaxErrorCode;

