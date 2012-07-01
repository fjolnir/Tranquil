%{
	#include <Foundation/Foundation.h>
	#include "TQSyntaxTree.h"
	#include <stdio.h>
	#include <stdlib.h>
	extern int yylineno;
	extern char* yytext;
	int yylex(void);
	// Bison doesn't like  @'s very much
	#define NSSTR(str) (@str)
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
	TQSyntaxNodeIdentifier *identifier;
	NSMutableArray *array;
}

%token tCLASS
%token tEND
%token tNUMBER
%token tSTRING
%token tIDENTIFIER

%type <number> number
%type <string> string
%type <identifier> identifier block_arg block_arg_identifier class_name
%type <variable> variable
/*%type <arg> arg*/
%type <block> block
%type <call> call
%type <class> class
/*%type <method> */
%type <message> message
%type <memberAccess> member_access
/*%type <binOp> */

%type <node> callee call_arg
%type <array> block_args call_args class_def methods

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
	  identifier { }
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
	  ':' block_arg opt_nl {
		TQSyntaxNodeArgument *arg = [[TQSyntaxNodeArgument alloc] initWithName:[$2 value] identifier:nil];
		$$ = [[NSMutableArray alloc] initWithObjects:arg, nil];
		[arg release];
		[$2 release];
	} 
	| block_args ':' block_arg opt_nl {
		TQSyntaxNodeArgument *arg = [[TQSyntaxNodeArgument alloc] initWithName:[$3 value] identifier:nil];
		[$$ addObject:arg];
		[arg release];
		[$3 release];
	}
	| block_args block_arg_identifier ':' block_arg opt_nl {
		TQSyntaxNodeArgument *arg = [[TQSyntaxNodeArgument alloc] initWithName:[$4 value] identifier:[$2 value]];
		[$$ addObject:arg];
		[arg release];
		[$2 release];
		[$4 release];
	}
	;
block_arg:
	  identifier {  }
	;
block_arg_identifier:
	  identifier {  }
	;

/* Block call */
call:
	  callee '.' {
		$$ = [[TQSyntaxNodeCall alloc] initWithCallee:$1];
		[$1 release];
	}
	| callee call_args '.' {
		$$ = [[TQSyntaxNodeCall alloc] initWithCallee:$1];
		[$$ setArguments:$2];
		[$1 release];
		[$2 release];
	}
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
	   tEND opt_nl {
		$$ = [[TQSyntaxNodeClass alloc] initWithName:[$2 objectAtIndex:0]
		                                  superClass:[$2 count] == 2 ? [$2 objectAtIndex:1] : nil];
		// TODO: Add methods
		if($3) {
			
		}
		[$2 release];
		[$3 release];
	}
	;
class_def: class_name '<' class_name {
		$$ = [[NSMutableArray alloc] initWithObjects:$1, $3, nil];
		[$1 release];
		[$3 release];
	}
	| class_name {
		$$ = [[NSMutableArray alloc] initWithObjects:$1, nil];
		[$1 release];
	}
	;
class_name: identifier
	;

methods: empty { $$ = nil; }
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
	  accessable '#' identifier {  }
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
	  number
	| string;

number: tNUMBER { $$ = [[TQSyntaxNodeNumber alloc] initWithDouble:atof(yytext)]; NSLog(NSSTR("Num: %@\n"), $$); }

string: tSTRING { $$ = [[TQSyntaxNodeString alloc] initWithCString:yytext]; NSLog(NSSTR("> String: %@"), $$); }

identifier: tIDENTIFIER {  $$ = [[TQSyntaxNodeIdentifier alloc] initWithCString:yytext]; NSLog(NSSTR("> Id: %@"), yylval.string); }
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
