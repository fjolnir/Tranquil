%{
	#include <llvm/Support/CommandLine.h>
	#include <Foundation/Foundation.h>
	#include <Tranquil.h>
	#include <stdio.h>
	#include <stdlib.h>
%}

%union {
	// Tokens
	double dbl;
	char *cStr;
	// Rules
	TQNode *node;
	TQNodeNumber *number;
	TQNodeString *string;
	TQNodeVariable *variable;
	TQNodeArgument *arg;
	TQNodeArgumentDef *argDef;
	TQNodeBlock *block;
	TQNodeCall *call;
	TQNodeClass *klass;
	TQNodeMethod *method;
	TQNodeMessage *message;
	TQNodeMemberAccess *memberAccess;
	TQNodeBinaryOperator *binOp;
	TQNodeIdentifier *identifier;
	TQNodeReturn *ret;
	TQNodeConstant *constant;
	NSMutableArray *array;
}

%{
	typedef struct {
		TQProgram *program;
		TQNode *currentNode;
	} TQParserState;

	int yylex(YYSTYPE *lvalp, YYLTYPE *llocp);
	extern "C" int yywrap(void);
	extern "C" int yyerror(YYLTYPE *yylocp, TQParserState *state,  const char *str);

	// Bison doesn't like @'s very much
	#define NSSTR(str) (@str)
%}

%pure_parser
%locations
%defines
%error-verbose
%parse-param { TQParserState *state }

%token <dbl>  tNUMBER
%token <cStr> tSTRING
%token <cStr> tCONSTANT
%token <cStr> tIDENTIFIER
%token <cStr> tBINOPERATOR

%type <number> Number
%type <string> String
%type <identifier> Identifier
%type <constant> Constant ClassName
%type <variable> Variable
%type <block> Block
%type <call> Call
%type <klass> Class
%type <method> Method ClassMethod InstanceMethod MethodDef
%type <message> Message
%type <memberAccess> Property
%type <binOp> Assignment
%type <ret> Return

%type <node> Literal Statement Expression Callee Lhs CallArg MessageArg MessageReceiver
%type <array> Statements CallArgs MessageArgs ClassBody ClassDef MethodArgs MethodBody BlockArgs

%start Program

%%
Program: { [state->program setRoot:[TQNodeRootBlock node]]; }
	| OptLn Statements Ln  {
		TQNodeBlock *root = [TQNodeRootBlock node];
		[root setStatements:$2];
		[state->program setRoot:root];
	}
	;

Statements:
	  Statement                       { $$ = [NSMutableArray arrayWithObjects:$1, nil]; }
	| Statements PeriodOrLn Statement { [$$ addObject:$3]; }
	;
Statement:
	  Call
	| Message
	| Assignment
	| Return
	| Class
	;

Call:
	  Callee '(' OptLn CallArgs OptLn ')' {
		$$ = [TQNodeCall nodeWithCallee:$1];
		[$$ setArguments:$4];
	}
	| Callee '(' OptLn ')' { $$ = [TQNodeCall nodeWithCallee:$1]; }
	;
Callee:
	  Variable
	| Property
	| Block
	;
CallArgs:
	  CallArg {
		TQNodeArgument *arg = [TQNodeArgument nodeWithPassedNode:$1 identifier:nil];
		$$ = [NSMutableArray arrayWithObjects:arg, nil];
	}
	| CallArgs OptLn ',' OptLn CallArg {
		TQNodeArgument *arg = [TQNodeArgument nodeWithPassedNode:$5 identifier:nil];
		[$$ addObject:arg];
	}
	;
CallArg:
	  Expression;

Message:
	  MessageReceiver Identifier {
		$$ = [TQNodeMessage nodeWithReceiver:$1];
		TQNodeArgument *arg = [TQNodeArgument nodeWithPassedNode:nil identifier:[$2 value]];
		NSMutableArray *args = [NSMutableArray arrayWithObjects:arg, nil];
		[$$ setArguments:args];
	}
	| MessageReceiver Identifier MessageArgs {
		$$ = [TQNodeMessage nodeWithReceiver:$1];
		[[$3 objectAtIndex:0] setIdentifier:[$2 value]];
		[$$ setArguments:$3];
	}
	| MessageReceiver MessageArgs {
		$$ = [TQNodeMessage nodeWithReceiver:$1];
		[$$ setArguments:$2];
	}

	;
MessageReceiver:
	  Callee
	| ClassName
	| Call
	| Literal
	;
/* TODO: Figure out how to relax this so a message can be split into multiple lines
         (Without requiring a dot at the end even when in parens) */
MessageArgs:
	 ':'  MessageArg {
		TQNodeArgument *arg = [TQNodeArgument nodeWithPassedNode:$2 identifier:nil];
		$$ = [NSMutableArray arrayWithObjects:arg, nil];
	}
	| MessageArgs Identifier ':'  MessageArg {
		TQNodeArgument *arg = [TQNodeArgument nodeWithPassedNode:$4 identifier:[$2 value]];
		[$$ addObject:arg];
	}
	;
/* TODO: Allow passing messages to messages without putting in parens(?) */
MessageArg:
	  Call
	| Variable
	| Literal
	| Block
	| '(' Expression ')' { $$ = $2; }
	;

Assignment:
	Lhs '=' Expression  { $$ = [TQNodeBinaryOperator nodeWithType:'=' left:$1 right:$3]; }
	;

Lhs:
	  Variable
	| Property
	;

Return:
	'^' Expression { $$ = [TQNodeReturn nodeWithValue:$2]; }
	;

Expression:
	  Message
	| Call
	| Variable
	| Literal
	| Block
	| '(' Expression ')' { $$ = $2; }
	;

Property:
	 Variable '#' Identifier
	| Property '#' Identifier
	;

Class: '#' ClassDef OptLn '{' OptLn
	      ClassBody OptLn
	   '}' {
		NSError *err = nil;
		$$ = [TQNodeClass nodeWithName:[[$2 objectAtIndex:0] value]
		                    superClass:[$2 count] == 2 ? [[$2 objectAtIndex:1] value] : nil
		                         error:&err];
		if(err)
			yyerror(&yylloc, state, [[err localizedDescription] UTF8String]);

		for(TQNodeMethod *method in $6) {
			if([method type] == kTQClassMethod)
				[[$$ classMethods] addObject:method];
			else
				[[$$ instanceMethods] addObject:method];
		}
	}
	|  '#' ClassDef OptLn '{' OptLn
	   '}' {
		NSError *err = nil;
		$$ = [TQNodeClass nodeWithName:[[$2 objectAtIndex:0] value]
		                    superClass:[$2 count] == 2 ? [[$2 objectAtIndex:1] value] : nil
		                         error:&err];
		if(err)
			yyerror(&yylloc, state, [[err localizedDescription] UTF8String]);
	}
	;
ClassDef:
	  ClassName '<' ClassName { $$ = [NSMutableArray arrayWithObjects:$1, $3, nil]; }
	| ClassName                   { $$ = [NSMutableArray arrayWithObjects:$1, nil]; }
	;
ClassBody:
	  Method             { $$ = [NSMutableArray arrayWithObjects:$1, nil]; }
	| ClassBody OptLn Method { [$$ addObject:$3]; }
	;
Method:
	  ClassMethod
	| InstanceMethod
	;
ClassMethod:    '+' MethodDef { $$ = $2; [$$ setType:kTQClassMethod]; }
	;
InstanceMethod: '-' MethodDef { $$ = $2; [$$ setType:kTQInstanceMethod]; }
	;
MethodDef:
	Identifier MethodArgs MethodBody {
		NSError *err = nil;
		$$ = [TQNodeMethod node];
		[[$2 objectAtIndex:0] setIdentifier:[$1 value]];
		for(TQNodeArgumentDef *arg in $2) {
			[$$ addArgument:arg error:&err];
			if(err)
				yyerror(&yylloc, state, [[err localizedDescription] UTF8String]);
		}
		[$$ setStatements:$3];
	}
	| Identifier MethodBody {
		NSError *err = nil;
		$$ = [TQNodeMethod node];
		TQNodeArgumentDef *arg = [TQNodeArgumentDef nodeWithLocalName:nil identifier:[$1 value]];
		[$$ addArgument:arg error:&err];
		if(err)
			yyerror(&yylloc, state, [[err localizedDescription] UTF8String]);
		[$$ setStatements:$2];
	}
	;
MethodArgs:
	':' Identifier OptLn {
		TQNodeArgumentDef *arg = [TQNodeArgumentDef nodeWithLocalName:[$2 value] identifier:nil];
		$$ = [NSMutableArray arrayWithObjects:arg, nil];
	}
	| MethodArgs ':' Identifier OptLn {
		TQNodeArgumentDef *arg = [TQNodeArgumentDef nodeWithLocalName:[$3 value] identifier:nil];
		[$$ addObject:arg];
	}
	| MethodArgs Identifier ':' Identifier OptLn {
		TQNodeArgumentDef *arg = [TQNodeArgumentDef nodeWithLocalName:[$4 value] identifier:[$2 value]];
		[$$ addObject:arg];
	}
	;
MethodBody:
	'{' OptLn
	   Statements Ln
	 '}' { $$ = $3; }
	| '{' OptLn '}' { $$ = nil; }
	| '`' Expression '`' { $$ = [NSMutableArray arrayWithObject:[TQNodeReturn nodeWithValue:$2]]; }
	;

Block:
	'{' OptLn BlockArgs '|' OptLn
		Statements Ln
	 '}' {
		NSError *err = nil;
		$$ = [TQNodeBlock node];
		for(TQNodeArgumentDef *arg in $3) {
			[$$ addArgument:arg error:&err];
			if(err)
				yyerror(&yylloc, state, [[err localizedDescription] UTF8String]);
		}
		[$$ setStatements:$6];
	}
	| '{' OptLn Statements '}' {
		$$ = [TQNodeBlock node];
		[$$ setStatements:$3];
	}
	| '{' OptLn '}' { $$ = [TQNodeBlock node]; }
	| '{' OptLn BlockArgs '|'  OptLn '}' { $$ = [TQNodeBlock node]; }
	| '`' BlockArgs '|' Expression '`' {
		NSError *err = nil;
		$$ = [TQNodeBlock node];
		for(TQNodeArgumentDef *arg in $2) {
			[$$ addArgument:arg error:&err];
			if(err)
				yyerror(&yylloc, state, [[err localizedDescription] UTF8String]);
		}
		[$$ setStatements:[NSArray arrayWithObject:[TQNodeReturn nodeWithValue:$4]]];
	}
	| '`' Expression '`' {
		$$ = [TQNodeBlock node];
		[$$ setStatements:[NSArray arrayWithObject:[TQNodeReturn nodeWithValue:$2]]];
	}
	;
BlockArgs:
	  Identifier OptLn {
		TQNodeArgumentDef *arg = [TQNodeArgumentDef nodeWithLocalName:[$1 value] identifier:nil];
		$$ = [NSMutableArray arrayWithObjects:arg, nil];
	}
	| BlockArgs ',' Identifier OptLn {
		TQNodeArgumentDef *arg = [TQNodeArgumentDef nodeWithLocalName:[$3 value] identifier:nil];
		[$$ addObject:arg];
	}
	;



ClassName: Constant;
Variable: Identifier { $$ = [TQNodeVariable nodeWithName:[$1 value]]; };

/* Basics */

OptLn:
	| OptLn '\n'
	;

Ln:
	  '\n'
	| Ln '\n'
	;
PeriodOrLn:
	  Ln
	| '.' OptLn
	;

Literal:
	  Number { $$ = $<node>1; }
	| String { $$ = $<node>1; }
	;
Number: tNUMBER { $$ = [TQNodeNumber nodeWithDouble:$1]; }
	;

String: tSTRING { $$ = [TQNodeString nodeWithCString:$1]; }
	;

Identifier: tIDENTIFIER {  $$ = [TQNodeIdentifier nodeWithCString:$1]; }
	;

Constant: tCONSTANT     {  $$ = [TQNodeConstant nodeWithCString:$1]; }
	;

%%

int yyerror(YYLTYPE *locp, TQParserState *state,  const char *str)
{
	fprintf(stderr, "%d:%d error: '%s'\n", locp->last_line, locp->last_column, str);

	exit(3);
	return 0;
}

int yywrap(void)
{
	return 1;
}

void parse()
{
	yydebug = true;
	TQParserState state = { [TQProgram programWithName:@"Test"], nil };
	yyparse(&state);
	NSLog(@"------------------------------------------");
	NSLog(@"%@", state.program);
	/*NSLog(@"------------------------------------------");*/
	[state.program run];
}

int main(int argc, char **argv)
{
	llvm::cl::ParseCommandLineOptions(argc, argv, 0, true);
	@autoreleasepool {
		parse();
	}
	return 0;
}
