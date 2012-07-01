%{
	#include <Foundation/Foundation.h>
	#include "TQSyntaxTree.h"
	#include <stdio.h>
	#include <stdlib.h>
%}

%union {
	// Tokens
	double dbl;
	char *cStr;
	// Rules
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

%{
	typedef struct {
		TQSyntaxNode *root;
		TQSyntaxNode *currentNode;
	} TQParserState;

	int yylex(YYSTYPE *lvalp, YYLTYPE *llocp);
	int yyerror(YYLTYPE *yylocp, TQParserState *state,  const char *str);

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
%type <class> class
%type <method> method class_method instance_method method_def
%type <message> message
%type <memberAccess> member_access
%type <binOp> assignment

%type <node> expression callee call_arg statement lhs message_receiver literal
%type <array> block_args call_args class_def methods statements method_body

%start program

%%
program: empty
	| opt_nl statements opt_nl { state->root = $<node>2; }
	;

assignment:
	  lhs '=' expression {
		$$ = [[TQSyntaxNodeBinaryOperator alloc] initWithType:'='
		                                                 left:$1
		                                                right:$3];
		[$1 release];
		[$3 release];
	}
	;

lhs:
	  member_access { $$ = $<node>1; }
	| variable      { $$ = $<node>1; }
	;

variable:
	  identifier {
		$$ = [[TQSyntaxNodeVariable alloc] initWithName:[$1 value]];
		[$1 release];
	}
	;

statements: statement {
		NSLog(NSSTR("----------- %@"), $1);
		$$ = [[NSMutableArray alloc] initWithObjects:$1, nil];
		[$1 release];
	}
	| statements opt_nl statement {
		NSLog(NSSTR("----------- %@"), $3);
		[$$ addObject:$3];
		[$3 release];
	}
	;

statement:
	  class                 { $$ = $<node>1; }
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
		$$ = [[TQSyntaxNodeBlock alloc] init];
		for(TQSyntaxNodeArgument *arg in $3) {
			[$$ addArgument:arg error:&err];
			if(err)
				yyerror(&yylloc, state, [[err localizedDescription] UTF8String]);
		}
		[$$ setStatements:$6];
		[$3 release];
		[$6 release];
	}
	| '{' opt_nl statements opt_nl '}' {
		$$ = [[TQSyntaxNodeBlock alloc] init];
		[$$ setStatements:$3];
		[$3 release];
	}
	| '{' opt_nl '}' { $$ = [[TQSyntaxNodeBlock alloc] init]; }
	;
block_args:
	  ':' block_arg opt_nl {
		TQSyntaxNodeArgument *arg = [[TQSyntaxNodeArgument alloc] initWithPassedNode:$2 identifier:nil];
		$$ = [[NSMutableArray alloc] initWithObjects:arg, nil];
		[arg release];
		[$2 release];
	} 
	| block_args ':' block_arg opt_nl {
		TQSyntaxNodeArgument *arg = [[TQSyntaxNodeArgument alloc] initWithPassedNode:$3 identifier:nil];
		[$$ addObject:arg];
		[arg release];
		[$3 release];
	}
	| block_args block_arg_identifier ':' block_arg opt_nl {
		TQSyntaxNodeArgument *arg = [[TQSyntaxNodeArgument alloc] initWithPassedNode:$4 identifier:[$2 value]];
		[$$ addObject:arg];
		[arg release];
		[$2 release];
		[$4 release];
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
	  ':' call_arg opt_nl {
		TQSyntaxNodeArgument *arg = [[TQSyntaxNodeArgument alloc] initWithPassedNode:$2 identifier:nil];
		$$ = [[NSMutableArray alloc] initWithObjects:arg, nil];
		[arg release];
		[$2 release];
	}
	| call_args ':' call_arg opt_nl {
		TQSyntaxNodeArgument *arg = [[TQSyntaxNodeArgument alloc] initWithPassedNode:$3 identifier:nil];
		[$$ addObject:arg];
		[arg release];
		[$3 release];
	}
	| call_args block_arg_identifier ':' call_arg opt_nl {
		TQSyntaxNodeArgument *arg = [[TQSyntaxNodeArgument alloc] initWithPassedNode:$4 identifier:[$2 value]];
		[$$ addObject:arg];
		[arg release];
		[$2 release];
		[$4 release];
	}
	;
call_arg:
	  block              { $$ = $<node>1; }
	/*| lhs '=' call_arg*/
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
		$$ = [[TQSyntaxNodeClass alloc] initWithName:[[$2 objectAtIndex:0] value]
		                                  superClass:[$2 count] == 2 ? [[$2 objectAtIndex:1] value] : nil
		                                       error:&err];
		if(err)
			yyerror(&yylloc, state, [[err localizedDescription] UTF8String]);

		for(TQSyntaxNodeMethod *method in $4) {
			if([method type] == kTQClassMethod)
				[[$$ classMethods] addObject:method];
			else
				[[$$ instanceMethods] addObject:method];
		}
		[$2 release];
		[$4 release];
	}
	|  tCLASS class_def opt_nl
	   tEND {
		NSError *err = nil;
		$$ = [[TQSyntaxNodeClass alloc] initWithName:[[$2 objectAtIndex:0] value]
		                                  superClass:[$2 count] == 2 ? [[$2 objectAtIndex:1] value] : nil
		                                       error:&err];
		if(err)
			yyerror(&yylloc, state, [[err localizedDescription] UTF8String]);
		[$2 release];
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

methods: method {
		$$ = [[NSMutableArray alloc] initWithObjects:$1, nil];
		[$1 release];
	}
	| methods opt_nl method {
		[$$ addObject:$3];
		[$3 release];
	}
	;
method: class_method
	| instance_method
	;
class_method: '+' method_def    { $$ = $2; [$$ setType:kTQClassMethod]; }
	;
instance_method: '-' method_def { $$ = $2; [$$ setType:kTQInstanceMethod]; }
	;
method_def: block_arg_identifier block_args method_body {
		$$ = [[TQSyntaxNodeMethod alloc] init];
		[[$2 objectAtIndex:0] setIdentifier:[$1 value]];
		[$$ setArguments:$2];
		[$$ setStatements:$3];

		[$1 release];
		[$2 release];
		[$3 release];
	}
	| block_arg_identifier method_body {
		NSError *err = nil;
		$$ = [[TQSyntaxNodeMethod alloc] init];
		TQSyntaxNodeArgument *arg = [[TQSyntaxNodeArgument alloc] initWithPassedNode:nil identifier:[$1 value]];
		[$$ addArgument:arg error:&err];
		if(err)
			yyerror(&yylloc, state, [[err localizedDescription] UTF8String]);
		[arg release];
		[$$ setStatements:$2];

		[$1 release];
		[$2 release];
	}
	;
method_body: '{' opt_nl
	   statements
	opt_nl '}' { $$ = $3; }
	| '{' opt_nl '}' { $$ = nil; }
	;

/* Object member access */
member_access:
	  message_receiver '#' identifier {
		$$ = [[TQSyntaxNodeMemberAccess alloc] initWithReceiver:$1 property:[$3 value]];
		[$1 release];
		[$3 release];
	}
	;

/* Message sending */
message:  message_receiver identifier  '.' {
		$$ = [[TQSyntaxNodeMessage alloc] initWithReceiver:$1];
		TQSyntaxNodeArgument *arg = [[TQSyntaxNodeArgument alloc] initWithPassedNode:nil identifier:[$2 value]];
		NSMutableArray *args = [[NSMutableArray alloc] initWithObjects:arg, nil];
		[arg release];
		[$$ setArguments:args];

		[args release];
		[$1 release];
		[$2 release];
	}
	| message_receiver identifier call_args '.' {
		$$ = [[TQSyntaxNodeMessage alloc] initWithReceiver:$1];
		[[$3 objectAtIndex:0] setIdentifier:[$2 value]];
		[$$ setArguments:$3];

		[$1 release];
		[$2 release];
		[$3 release];
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
number: tNUMBER { $$ = [[TQSyntaxNodeNumber alloc] initWithDouble:$1]; }
	;

string: tSTRING { $$ = [[TQSyntaxNodeString alloc] initWithCString:$1]; }
	;

identifier: tIDENTIFIER {  $$ = [[TQSyntaxNodeIdentifier alloc] initWithCString:$1]; }
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
	TQParserState state = { nil, nil };
	yydebug = 5;
	yyparse(&state);
	NSLog(@"------------------------------------------");
	for(TQSyntaxNode *node in (NSArray*)state.root) {
		NSLog(@"%@", node);
	}
	NSLog(@"------------------------------------------");

	/*NSLog(@"done %@", state.root);*/
}

int main()
{
	@autoreleasepool {
		parse();
	}
	return 0;
}
