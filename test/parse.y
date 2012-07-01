%{
	#include <Foundation/Foundation.h>
	#include "TQSyntaxTree.h"
	#include <stdio.h>
	#include <stdlib.h>
	extern int yylineno;
	extern char* yytext;
	int yylex(void);
%}

%union {
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
}

%token tCLASS                      /* class */
%token tEND                        /* end */
%token <dbl> tNUMBER               /* <number> */
%token <text> tSTRING              /* Contents of a quoted string */
%token <text> tIDENTIFIER          /* An identifier, non quoted string matching [a-zA-Z0-9_]+ */

%type<text> variable assignment expression lhs literal class member_access block_arg_identifier methods method accessable
%type<block> block
%start statements

%%
assignment:
	  lhs '=' expression  { }
	;

lhs:
	  member_access
	| variable
	;

variable:
	  tIDENTIFIER { }
	;

statements: empty
	| statements statement
	;

statement:
	  class
	| expression
	;

expression:
	  message
	| block
	| call
	| assignment opt_nl
	| lhs
	| literal
	| '(' expression rparen
	;

callee:
	  block
	| lhs
	| literal
	| '(' expression ')'
	;

/* Block definition */
block:
	  '{' opt_nl block_args '|'
	      statements
	  '}'
	| '{' statements '}' { $$ = [[TQSyntaxNodeBlock alloc] init]; }
	;
block_args:
	  ':' block_arg opt_nl
	| block_args ':' block_arg opt_nl
	| block_args block_arg_identifier ':' block_arg opt_nl
	;
block_arg:
	  tIDENTIFIER {  }
	;
block_arg_identifier:
	  tIDENTIFIER {  }
	;

/* Block call */
call:
	  callee '.'
	| callee call_args '.'
	;
call_args:
	  ':' call_arg opt_nl
	| call_args ':' call_arg opt_nl
	| call_args block_arg_identifier ':' call_arg opt_nl
	;
call_arg:
	  block 
	| lhs '=' call_arg
	| lhs
	| literal
	| '(' expression ')'
	;

/* Class definition */
class: tCLASS class_def
	      methods opt_nl
	   tEND opt_nl
	;
class_def: class_name '<' tIDENTIFIER
	| class_name
	;
class_name: tIDENTIFIER
	;

methods: empty
	| methods opt_nl method
	;
method: class_method
	| instance_method
class_method: '+' method_def
	;
instance_method: '-' method_def
	;
method_def: block_arg_identifier block_args method_body
	| block_arg_identifier method_body
	;
method_body: '{'
	   statements
	'}'

/* Object member access */
member_access:
	  accessable '#' tIDENTIFIER {  }
	;
accessable: lhs
	| '(' expression rparen
	;

/* Message sending */
message: message_receiver call
	;
message_receiver:
	  lhs
	| literal
	| '(' expression ')'
	;

/* Basics */

empty:
	;

opt_nl:
	| opt_nl '\n'
	;

rparen: opt_nl ')'
	;

/*term: '\n'*/
	/*;*/

literal:
	  tNUMBER
	| tSTRING
	;

%%

int yyerror(char *str)
{
	fprintf(stderr, "%d: error: '%s' at '%s'\n", yylineno, str, yytext);

	exit(3);
	return 0;
}

int yywrap(void) {
	return 1;
}

int main()
{
	yydebug = 5;
	yyparse();
	return 0;
}
