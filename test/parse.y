%{
	#include <Foundation/Foundation.h>
	#include "TQProgram.h"
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
	TQNodeBlock *block;
	TQNodeCall *call;
	TQNodeClass *klass;
	TQNodeMethod *method;
	TQNodeMessage *message;
	TQNodeMemberAccess *memberAccess;
	TQNodeBinaryOperator *binOp;
	TQNodeIdentifier *identifier;
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

%token tCLASS
%token tEND
%token tRETURN
%token <dbl>  tNUMBER
%token <cStr> tSTRING
%token <cStr> tIDENTIFIER

%type <number> number
%type <string> string
%type <identifier> identifier block_arg block_arg_identifier class_name
%type <variable> variable
%type <block> block
%type <call> call
%type <klass> class
%type <method> method class_method instance_method method_def
%type <message> message
%type <memberAccess> member_access
%type <binOp> assignment

%type <node> expression callee call_arg statement lhs message_receiver literal
%type <array> block_args call_args class_def methods statements method_body

%start program

%%
program: empty
	| opt_nl statements opt_nl {
		TQNodeBlock *root = [TQNodeBlock node];
		[root setStatements:$2];
		[state->program setRoot:root];
	}
	;

assignment:
	  lhs '=' expression { $$ = [TQNodeBinaryOperator nodeWithType:'=' left:$1 right:$3]; }
	;

lhs:
	  member_access { $$ = $<node>1; }
	| variable      { $$ = $<node>1; }
	;

variable:
	  identifier { $$ = [TQNodeVariable nodeWithName:[$1 value]]; }
	;

statements: statement             { NSLog(NSSTR("----------- %@"), $1); $$ = [NSMutableArray arrayWithObjects:$1, nil]; }
	| statements opt_nl statement { NSLog(NSSTR("----------- %@"), $3); [$$ addObject:$3]; }
	;

statement:
	  class                 { $$ = $<node>1; }
	| tRETURN call_arg '.'  { $$ = [TQNodeReturn nodeWithValue:$2]; }
	| tRETURN '.'           { $$ = [TQNodeReturn nodeWithValue:nil]; }
	| message               { $$ = $<node>1; }
	| call                  { $$ = $<node>1; }
	| assignment '\n'       { $$ = $<node>1; }
	;

expression:
	  message               { $$ = $<node>1; }
	| assignment            { $$ = $<node>1; }
	| block                 { $$ = $<node>1; }
	| call                  { $$ = $<node>1; }
	| member_access         { $$ = $<node>1; }
	| variable              { $$ = $<node>1; }
	| literal               { $$ = $<node>1; }
	| '(' expression ')'    { $$ = $2;       }
	;

callee:
	  block                 { $$ = $<node>1; }
	| member_access         { $$ = $<node>1; }
	| variable              { $$ = $<node>1; }
	| literal               { $$ = $<node>1; }
	| '(' expression ')'    { $$ = $2;       }
	;

/* Block definition */
block:
	  '{' opt_nl block_args '|' opt_nl
	      statements
	  opt_nl '}' {
		NSError *err = nil;
		$$ = [TQNodeBlock node];
		for(TQNodeArgument *arg in $3) {
			[$$ addArgument:arg error:&err];
			if(err)
				yyerror(&yylloc, state, [[err localizedDescription] UTF8String]);
		}
		[$$ setStatements:$6];
	}
	| '{' opt_nl statements opt_nl '}' {
		$$ = [TQNodeBlock node];
		[$$ setStatements:$3];
	}
	| '{' opt_nl '}' { $$ = [TQNodeBlock node]; }
	;
block_args:
	  ':' block_arg opt_nl {
		TQNodeArgument *arg = [TQNodeArgument nodeWithPassedNode:$2 identifier:nil];
		$$ = [NSMutableArray arrayWithObjects:arg, nil];
	} 
	| block_args ':' block_arg opt_nl {
		TQNodeArgument *arg = [TQNodeArgument nodeWithPassedNode:$3 identifier:nil];
		[$$ addObject:arg];
	}
	| block_args block_arg_identifier ':' block_arg opt_nl {
		TQNodeArgument *arg = [TQNodeArgument nodeWithPassedNode:$4 identifier:[$2 value]];
		[$$ addObject:arg];
	}
	;
block_arg:
	  identifier
	;
block_arg_identifier:
	  identifier
	;

/* Block call */
call:
	  callee '.' { $$ = [TQNodeCall nodeWithCallee:$1]; }
	| callee call_args '.' {
		$$ = [TQNodeCall nodeWithCallee:$1];
		[$$ setArguments:$2];
	}
	;
call_args:
	  ':' call_arg opt_nl {
		TQNodeArgument *arg = [TQNodeArgument nodeWithPassedNode:$2 identifier:nil];
		$$ = [NSMutableArray arrayWithObjects:arg, nil];
	}
	| call_args ':' call_arg opt_nl {
		TQNodeArgument *arg = [TQNodeArgument nodeWithPassedNode:$3 identifier:nil];
		[$$ addObject:arg];
	}
	| call_args block_arg_identifier ':' call_arg opt_nl {
		TQNodeArgument *arg = [TQNodeArgument nodeWithPassedNode:$4 identifier:[$2 value]];
		[$$ addObject:arg];
	}
	;
call_arg:
	  block              { $$ = $<node>1; }
	| lhs '=' call_arg   { $$ = [TQNodeBinaryOperator nodeWithType:'=' left:$1 right:$3]; }
	| member_access      { $$ = $<node>1; }
	| variable           { $$ = $<node>1; }
	| literal            { $$ = $<node>1; }
	| '(' expression ')' { $$ = $2; }
	;

/* Class definition */
class: tCLASS class_def opt_nl
	      methods opt_nl
	   tEND {
		NSError *err = nil;
		$$ = [TQNodeClass nodeWithName:[[$2 objectAtIndex:0] value]
		                    superClass:[$2 count] == 2 ? [[$2 objectAtIndex:1] value] : nil
		                         error:&err];
		if(err)
			yyerror(&yylloc, state, [[err localizedDescription] UTF8String]);

		for(TQNodeMethod *method in $4) {
			if([method type] == kTQClassMethod)
				[[$$ classMethods] addObject:method];
			else
				[[$$ instanceMethods] addObject:method];
		}
	}
	|  tCLASS class_def opt_nl
	   tEND {
		NSError *err = nil;
		$$ = [TQNodeClass nodeWithName:[[$2 objectAtIndex:0] value]
		                    superClass:[$2 count] == 2 ? [[$2 objectAtIndex:1] value] : nil
		                         error:&err];
		if(err)
			yyerror(&yylloc, state, [[err localizedDescription] UTF8String]);
	}
	;
class_def: class_name '<' class_name { $$ = [NSMutableArray arrayWithObjects:$1, $3, nil]; }
	| class_name                     { $$ = [NSMutableArray arrayWithObjects:$1, nil]; }
	;
class_name: identifier
	;

methods: method             { $$ = [NSMutableArray arrayWithObjects:$1, nil]; }
	| methods opt_nl method { [$$ addObject:$3]; }
	;
method: class_method
	| instance_method
	;
class_method: '+' method_def    { $$ = $2; [$$ setType:kTQClassMethod]; }
	;
instance_method: '-' method_def { $$ = $2; [$$ setType:kTQInstanceMethod]; }
	;
method_def: block_arg_identifier block_args method_body {
		$$ = [TQNodeMethod node];
		[[$2 objectAtIndex:0] setIdentifier:[$1 value]];
		[$$ setArguments:$2];
		[$$ setStatements:$3];
	}
	| block_arg_identifier method_body {
		NSError *err = nil;
		$$ = [TQNodeMethod node];
		TQNodeArgument *arg = [TQNodeArgument nodeWithPassedNode:nil identifier:[$1 value]];
		[$$ addArgument:arg error:&err];
		if(err)
			yyerror(&yylloc, state, [[err localizedDescription] UTF8String]);
		[$$ setStatements:$2];
	}
	;
method_body: '{' opt_nl
	   statements
	opt_nl '}' { $$ = $3; }
	| '{' opt_nl '}' { $$ = nil; }
	;

/* Object member access */
member_access:
	  message_receiver '#' identifier { $$ = [TQNodeMemberAccess nodeWithReceiver:$1 property:[$3 value]]; }
	;

/* Message sending */
message:  message_receiver identifier  '.' {
		$$ = [TQNodeMessage nodeWithReceiver:$1];
		TQNodeArgument *arg = [TQNodeArgument nodeWithPassedNode:nil identifier:[$2 value]];
		NSMutableArray *args = [NSMutableArray arrayWithObjects:arg, nil];
		[$$ setArguments:args];
	}
	| message_receiver identifier call_args '.' {
		$$ = [TQNodeMessage nodeWithReceiver:$1];
		[[$3 objectAtIndex:0] setIdentifier:[$2 value]];
		[$$ setArguments:$3];
	}
	;
message_receiver:
	  member_access      { $$ = $<node>1; }
	| variable           { $$ = $<node>1; }
	| literal
	| '(' expression ')' { $$ = $2; }
	;

/* Basics */

empty:
	;

opt_nl: empty
	| opt_nl '\n'
	;

/*opt_dot: empty*/
	/*| '.'*/
	/*;*/

/*rparen: opt_nl ')'
	;*/

/*term: '\n'*/
	/*;*/

literal:
	  number { $$ = $<node>1; }
	| string { $$ = $<node>1; }
	;
number: tNUMBER { $$ = [TQNodeNumber nodeWithDouble:$1]; }
	;

string: tSTRING { $$ = [TQNodeString nodeWithCString:$1]; }
	;

identifier: tIDENTIFIER {  $$ = [TQNodeIdentifier nodeWithCString:$1]; }
	;
%%

int yyerror(YYLTYPE *locp, TQParserState *state,  const char *str)
{
	fprintf(stderr, "%d:%d error: '%s'\n", locp->first_line, locp->first_column, str);

	exit(3);
	return 0;
}

int yywrap(void)
{
	return 1;
}

void parse()
{
	TQParserState state = { [TQProgram programWithName:@"Test"], nil };
	yydebug = 5;
	yyparse(&state);
	NSLog(@"------------------------------------------");
	NSLog(@"%@", state.program);
	NSLog(@"------------------------------------------");
	[state.program run];
}

int main()
{
	@autoreleasepool {
		parse();
	}
	return 0;
}
