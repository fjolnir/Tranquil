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

@interface TQSyntaxNode : NSObject
- (BOOL)generateCodeInModule:(llvm::Module *)aModule :(NSError **)aoErr;
@end

@interface TQSyntaxNodeReturn : TQSyntaxNode
@property(readwrite, retain) TQSyntaxNode *value;
- (id)initWithValue:(TQSyntaxNode *)aValue;
@end

@interface TQSyntaxNodeVariable : TQSyntaxNode
@property(readwrite, retain) NSString *name;
- (id)initWithName:(NSString *)aName;
@end

@interface TQSyntaxNodeString : TQSyntaxNode
@property(readwrite, retain) NSString *value;
- (id)initWithCString:(const char *)aStr;
@end

@interface TQSyntaxNodeIdentifier : TQSyntaxNodeString
@end

@interface TQSyntaxNodeNumber : TQSyntaxNode
@property(readwrite, retain) NSNumber *value;
- (id)initWithDouble:(double)aDouble;
@end

// An argument to block (name: arg)
@interface TQSyntaxNodeArgument : TQSyntaxNode
@property(readwrite, retain) NSString *identifier;     // The argument identifier, that is, the portion before ':'
@property(readwrite, retain) TQSyntaxNode *passedNode; // The node after ':'
- (id)initWithPassedNode:(TQSyntaxNode *)aNode identifier:(NSString *)aIdentifier;
@end

// A block definition ({ :arg | body })
@interface TQSyntaxNodeBlock : TQSyntaxNode
@property(readwrite, copy) NSMutableArray *arguments;
@property(readwrite, copy) NSMutableArray *statements;
- (BOOL)addArgument:(TQSyntaxNodeArgument *)aArgument error:(NSError **)aoError;
@end

// A call to a block (block: argument.)
@interface TQSyntaxNodeCall : TQSyntaxNode
@property(readwrite, retain) TQSyntaxNode *callee;
@property(readwrite, copy) NSMutableArray *arguments;
- (id)initWithCallee:(TQSyntaxNode *)aCallee;
@end


// A class definition (class Name < SuperClass\n methods\n end)
@interface TQSyntaxNodeClass : TQSyntaxNode
@property(readwrite, retain) NSString *name;
@property(readwrite, retain) NSString *superClassName;
@property(readwrite, copy) NSMutableArray *classMethods;
@property(readwrite, copy) NSMutableArray *instanceMethods;
- (id)initWithName:(NSString *)aName superClass:(NSString *)aSuperClass error:(NSError **)aoError;
@end

typedef enum {
	kTQClassMethod,
	kTQInstanceMethod
} TQMethodType;

// A method definition (+ aMethod: argument { body })
@interface TQSyntaxNodeMethod : TQSyntaxNodeBlock
@property(readwrite, assign) TQMethodType type;
- (id)initWithType:(TQMethodType)aType;
@end

// A message to an object (object message: argument.)
@interface TQSyntaxNodeMessage : TQSyntaxNode
@property(readwrite, retain) TQSyntaxNode *receiver;
@property(readwrite, copy) NSMutableArray *arguments;
- (id)initWithReceiver:(TQSyntaxNode *)aNode;
@end

// Object member access (object#member)
@interface TQSyntaxNodeMemberAccess : TQSyntaxNode
@property(readwrite, retain) TQSyntaxNode *receiver;
@property(readwrite, copy) NSString *property;
- (id)initWithReceiver:(TQSyntaxNode *)aReceiver property:(NSString *)aKey;
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
@interface TQSyntaxNodeBinaryOperator : TQSyntaxNode
@property(readwrite, assign) TQOperatorType type;
@property(readwrite, retain) TQSyntaxNode *left;
@property(readwrite, retain) TQSyntaxNode *right;
- (id)initWithType:(TQOperatorType)aType left:(TQSyntaxNode *)aLeft right:(TQSyntaxNode *)aRight;
@end


@interface TQSyntaxTree : NSObject
@end

#endif
