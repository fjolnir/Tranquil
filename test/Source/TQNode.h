#include <Foundation/Foundation.h>
#include <llvm/Module.h>
#include <llvm/BasicBlock.h>
#include <llvm/LLVMContext.h>
#include <llvm/DerivedTypes.h>
#include <llvm/Constants.h>
#include <llvm/GlobalVariable.h>
#include <llvm/Function.h>
#include <llvm/CallingConv.h>
#include <llvm/BasicBlock.h>
#include <llvm/Instructions.h>
#include <llvm/InlineAsm.h>
#include <llvm/Support/FormattedStream.h>
#include <llvm/Support/MathExtras.h>
#include <llvm/Pass.h>
#include <llvm/PassManager.h>
#include <llvm/ADT/SmallVector.h>
#include <llvm/Analysis/Verifier.h>
#include <llvm/Assembly/PrintModulePass.h>

@class TQNodeBlock, TQProgram;

extern NSString * const kTQSyntaxErrorDomain;

typedef enum {
	kTQUnexpectedIdentifier = 1,
	kTQInvalidClassName,
	kTQInvalidAssignee
} TQSyntaxErrorCode;

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
				NSString *errorDesc = [[NSString alloc] initWithFormat:fmt, ##__VA_ARGS__]; \
				NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorDesc \
				                                                     forKey:NSLocalizedDescriptionKey]; \
				[errorDesc release]; \
				*aoError = [NSError errorWithDomain:(errDomain) code:(errCode) userInfo:userInfo]; \
				[userInfo release]; \
			} \
			TQLog(fmt, ##__VA_ARGS__); \
			return retVal; \
		} \
	} while(0)

#else
	#define TQLog(fmt, ...)
    #define TQAssert(cond, fmt, ...)
#endif

@interface TQNode : NSObject
+ (TQNode *)node;
- (BOOL)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr;
@end
