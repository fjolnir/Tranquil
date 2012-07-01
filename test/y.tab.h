#define tCLASS 257
#define tEND 258
#define tNUMBER 259
#define tSTRING 260
#define tIDENTIFIER 261
#ifdef YYSTYPE
#undef  YYSTYPE_IS_DECLARED
#define YYSTYPE_IS_DECLARED 1
#endif
#ifndef YYSTYPE_IS_DECLARED
#define YYSTYPE_IS_DECLARED 1
typedef union {
	TQSyntaxNode *node;
	TQSyntaxNodeNumber *number;
	TQSyntaxNodeString *string;
	TQSyntaxNodeVariable *variable;
	TQSyntaxNodeArgument *arg;
	TQSyntaxNodeBlock *block;
	TQSyntaxNodeCall *call;
	TQSyntaxNodeClass *class;
	TQSyntaxNodeMethod *method;
	TQSyntaxNodeMessage *message;
	TQSyntaxNodeMemberAccess *memberAccess;
	TQSyntaxNodeBinaryOperator *binOp;
	TQSyntaxNodeIdentifier *identifier;
	NSMutableArray *array;
} YYSTYPE;
#endif /* !YYSTYPE_IS_DECLARED */
extern YYSTYPE yylval;
