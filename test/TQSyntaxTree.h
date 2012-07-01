#ifndef _TQ_SYNTAXTREE_H_
#define _TQ_SYNTAXTREE_H_


@interface TQSyntaxNode : NSObject
	- (BOOL)generateCode:(NSError **)aoErr;
@end

@interface TQSyntaxNodeVariable : TQSyntaxNode
@property(readwrite, retain) NSString *name;
@end

@interface TQSyntaxNodeString : TQSyntaxNode
@property(readwrite, retain) NSString *value;
@end

@interface TQSyntaxNodeNumber : TQSyntaxNode
@property(readwrite, retain) NSNumber *value;
@end

// An argument to block (name: arg)
@interface TQSyntaxNodeArgument : TQSyntaxNode
@property(readwrite, retain) NSString *identifier; // The argument identifier, that is, the portion before ':'
@property(readwrite, retain) NSString *name;       // The variable name for the argument
@end

// A block definition ({ :arg | body })
@interface TQSyntaxNodeBlock : TQSyntaxNode
@property(readwrite, copy) NSMutableArray *arguments;
@property(readwrite, copy) NSMutableArray *statements;

- (BOOL)addArgument:(TQSyntaxNodeArgument *)aArgument error:(NSError **)aError;
@end

// A call to a block (block: argument.)
@interface TQSyntaxNodeCall : TQSyntaxNode
@property(readwrite, retain) TQSyntaxNode *callee;
@property(readwrite, copy) NSMutableArray *arguments;
@end


// A class definition (class Name < SuperClass\n methods\n end)
@interface TQSyntaxNodeClass : TQSyntaxNode
@property(readwrite, retain) NSString *name;
@property(readwrite, retain) NSString *superClassName;
@property(readwrite, copy) NSMutableArray *classMethods;
@property(readwrite, copy) NSMutableArray *instanceMethods;
@end

typedef enum {
	kTQClassMethod,
	kTQInstanceMethod
} TQMethodType;
// A method definition (+ aMethod: argument { body })
@interface TQSyntaxNodeMethod : TQSyntaxNodeBlock
@property(readwrite, assign) TQMethodType type;
@end

// A message to an object (object message: argument.)
@interface TQSyntaxNodeMessage : TQSyntaxNode
@property(readwrite, retain) TQSyntaxNode *receiver;
@property(readwrite, assign) SEL selector;
@property(readwrite, copy) NSMutableArray *arguments;
@end

// Object member access (object#member)
@interface TQSyntaxNodeMemberAccess : TQSyntaxNode
@property(readwrite, retain) TQSyntaxNode *receiver;
@property(readwrite, copy) NSString *key;
@end

typedef enum {
	kTQOperatorAssign = '=',
	kTQOperatorPlus = '+',
	kTQOperatorMinus = '-',
	kTQOperatorMultiply = '*',
	kTQOperatorDivide = '/',
	kTQOperatorGreater = '>',
	kTQOperatorLesser = '<'
} TQOperatorType;
// Binary operator (a <operator> b)
@interface TQSyntaxNodeBinaryOperator : TQSyntaxNode
@property(readwrite, assign) TQOperatorType type;
@property(readwrite, retain) TQSyntaxNode *left;
@property(readwrite, retain) TQSyntaxNode *right;
@end


@interface TQSyntaxTree : NSObject {
}
@end

#endif
