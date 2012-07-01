#import <Tranquil/TQObject.h>
#import <Tranquil/TQProgram.h>
#import <Tranquil/Runtime/TQRuntime.h>
#import <Tranquil/Runtime/TQOperators.h>
#import <Tranquil/Runtime/TQNumber.h>
#import <Tranquil/CodeGen/TQNode.h>
#import <Tranquil/CodeGen/TQNodeArgument.h>
#import <Tranquil/CodeGen/TQNodeArgumentDef.h>
#import <Tranquil/CodeGen/TQNodeOperator.h>
#import <Tranquil/CodeGen/TQNodeBlock.h>
#import <Tranquil/CodeGen/TQNodeCall.h>
#import <Tranquil/CodeGen/TQNodeClass.h>
#import <Tranquil/CodeGen/TQNodeMemberAccess.h>
#import <Tranquil/CodeGen/TQNodeMessage.h>
#import <Tranquil/CodeGen/TQNodeMethod.h>
#import <Tranquil/CodeGen/TQNodeNumber.h>
#import <Tranquil/CodeGen/TQNodeReturn.h>
#import <Tranquil/CodeGen/TQNodeString.h>
#import <Tranquil/CodeGen/TQNodeVariable.h>
#import <Tranquil/CodeGen/TQNodeConstant.h>
#import <Tranquil/CodeGen/TQNodeNil.h>
#import <Tranquil/CodeGen/TQNodeArray.h>
#import <Tranquil/CodeGen/TQNodeDictionary.h>
#import <Tranquil/CodeGen/TQNodeRegex.h>
#import <Tranquil/CodeGen/TQNodeConditionalBlock.h>
#import <Tranquil/CodeGen/TQNodeLoopBlock.h>


#ifdef DEBUG
    #define TQLog(fmt, ...) NSLog(@"%s:%u (%s): " fmt "\n", __FILE__, __LINE__, __func__, ## __VA_ARGS__)
    #define TQLog_min(fmt, ...)  NSLog(fmt "\n", ## __VA_ARGS__)


#define TQAssert(cond, fmt, ...) \
    do { \
        if(!(cond)) { \
            TQLog(@"Assertion failed:" fmt, ##__VA_ARGS__); \
            abort(); \
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

