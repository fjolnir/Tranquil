#ifndef _TQ_SYNTAXTREE_H_
#define _TQ_SYNTAXTREE_H_

#include <Foundation/Foundation.h>
#include <llvm/Module.h>

#ifdef DEBUG
	#define TQLog(fmt, ...) NSLog(@"%s:%u (%s): " fmt "\n", __FILE__, __LINE__, __func__, ## __VA_ARGS__)
	#define TQLog_min(fmt, ...)  NSLog(fmt "\n", ## __VA_ARGS__)

extern NSString * const kTQSyntaxErrorDomain;

typedef enum {
	kTQUnexpectedIdentifier = 1,
	kTQInvalidClassName,
} TQSyntaxErrorCode;

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
- (BOOL)generateCodeInModule:(llvm::Module *)aModule :(NSError **)aoErr;
@end

@interface TQNodeReturn : TQNode
@property(readwrite, retain) TQNode *value;
+ (TQNodeReturn *)nodeWithValue:(TQNode *)aValue;
- (id)initWithValue:(TQNode *)aValue;
@end

@interface TQNodeVariable : TQNode
@property(readwrite, retain) NSString *name;
+ (TQNodeVariable *)nodeWithName:(NSString *)aName;
- (id)initWithName:(NSString *)aName;
@end

@interface TQNodeString : TQNode
@property(readwrite, retain) NSString *value;
+ (TQNodeString *)nodeWithCString:(const char *)aStr;
- (id)initWithCString:(const char *)aStr;
@end

@interface TQNodeIdentifier : TQNodeString
+ (TQNodeIdentifier *)nodeWithCString:(const char *)aStr;
@end

@interface TQNodeNumber : TQNode
@property(readwrite, retain) NSNumber *value;
+ (TQNodeNumber *)nodeWithDouble:(double)aDouble;
- (id)initWithDouble:(double)aDouble;
@end

// An argument to block (name: arg)
@interface TQNodeArgument : TQNode
@property(readwrite, retain) NSString *identifier;     // The argument identifier, that is, the portion before ':'
@property(readwrite, retain) TQNode *passedNode; // The node after ':'
+ (TQNodeArgument *)nodeWithPassedNode:(TQNode *)aNode identifier:(NSString *)aIdentifier;
- (id)initWithPassedNode:(TQNode *)aNode identifier:(NSString *)aIdentifier;
@end

// A block definition ({ :arg | body })
@interface TQNodeBlock : TQNode
@property(readwrite, copy) NSMutableArray *arguments;
@property(readwrite, copy) NSMutableArray *statements;
+ (TQNodeBlock *)node;
- (BOOL)addArgument:(TQNodeArgument *)aArgument error:(NSError **)aoError;
@end

// A call to a block (block: argument.)
@interface TQNodeCall : TQNode
@property(readwrite, retain) TQNode *callee;
@property(readwrite, copy) NSMutableArray *arguments;
+ (TQNodeCall *)nodeWithCallee:(TQNode *)aCallee;
- (id)initWithCallee:(TQNode *)aCallee;
@end


// A class definition (class Name < SuperClass\n methods\n end)
@interface TQNodeClass : TQNode
@property(readwrite, retain) NSString *name;
@property(readwrite, retain) NSString *superClassName;
@property(readwrite, copy) NSMutableArray *classMethods;
@property(readwrite, copy) NSMutableArray *instanceMethods;
+ (TQNodeClass *)nodeWithName:(NSString *)aName superClass:(NSString *)aSuperClass error:(NSError **)aoError;
- (id)initWithName:(NSString *)aName superClass:(NSString *)aSuperClass error:(NSError **)aoError;
@end

typedef enum {
	kTQClassMethod,
	kTQInstanceMethod
} TQMethodType;

// A method definition (+ aMethod: argument { body })
@interface TQNodeMethod : TQNodeBlock
@property(readwrite, assign) TQMethodType type;
+ (TQNodeMethod *)node;
+ (TQNodeMethod *)nodeWithType:(TQMethodType)aType;
- (id)initWithType:(TQMethodType)aType;
@end

// A message to an object (object message: argument.)
@interface TQNodeMessage : TQNode
@property(readwrite, retain) TQNode *receiver;
@property(readwrite, copy) NSMutableArray *arguments;
+ (TQNodeMessage *)nodeWithReceiver:(TQNode *)aNode;
- (id)initWithReceiver:(TQNode *)aNode;
@end

// Object member access (object#member)
@interface TQNodeMemberAccess : TQNode
@property(readwrite, retain) TQNode *receiver;
@property(readwrite, copy) NSString *property;
+ (TQNodeMemberAccess *)nodeWithReceiver:(TQNode *)aReceiver property:(NSString *)aKey;
- (id)initWithReceiver:(TQNode *)aReceiver property:(NSString *)aKey;
@end

enum {
	kTQOperatorAssign = '=',
	kTQOperatorPlus = '+',
	kTQOperatorMinus = '-',
	kTQOperatorMultiply = '*',
	kTQOperatorDivide = '/',
	kTQOperatorGreater = '>',
	kTQOperatorLesser = '<'
};
typedef char TQOperatorType;
// Binary operator (a <operator> b)
@interface TQNodeBinaryOperator : TQNode
@property(readwrite, assign) TQOperatorType type;
@property(readwrite, retain) TQNode *left;
@property(readwrite, retain) TQNode *right;
+ (TQNodeBinaryOperator *)nodeWithType:(TQOperatorType)aType left:(TQNode *)aLeft right:(TQNode *)aRight;
- (id)initWithType:(TQOperatorType)aType left:(TQNode *)aLeft right:(TQNode *)aRight;
@end


@interface TQProgram : NSObject
@property(readwrite, retain) TQNode *rootNode;

@end

#endif
