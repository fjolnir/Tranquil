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
%token <cStr> tCONSTANT
%token <cStr> tIDENTIFIER

%type <number> number
%type <string> string
%type <identifier> identifier constant
%type <variable> variable
%type <block> block
%type <call> call
%type <klass> class
%type <method> method class_method instance_method method_def
%type <message> message message_unterminated
%type <memberAccess> member_access
%type <binOp> assignment
%type <ret> return

%type <node> expression expr_in_parens callee call_arg statement lhs message_receiver literal message_arg
%type <array> block_args call_args class_def methods statements method_body message_args method_args

%start program

%%
program: { [state->program setRoot:[TQNodeRootBlock node]]; }
	| opt_nl statements opt_nl {
		TQNodeBlock *root = [TQNodeRootBlock node];
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

statements: statement {
		NSLog(NSSTR("----------- %@"), $1);
		$$ = [NSMutableArray arrayWithObjects:$1, nil];
	}
	| statements opt_nl statement {
		NSLog(NSSTR("----------- %@"), $3);
		[$$ addObject:$3];
	}
	;

return:
	  tRETURN call_arg term  { $$ = [TQNodeReturn nodeWithValue:$2]; }
	| tRETURN term          { $$ = [TQNodeReturn nodeWithValue:nil]; }

statement:
	  class                 { $$ = $<node>1; }
	| return                { $$ = $<node>1; }
	| message               { $$ = $<node>1; }
	| call '\n'             { $$ = $<node>1; }
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
	| expr_in_parens        { $$ = $<node>1; }
	;
expr_in_parens:
	  '(' message_unterminated ')'    { $$ = $<node>2; }
	| '(' expression ')'    { $$ = $<node>2; }
	;

callee:
	  block                 { $$ = $<node>1; }
	| member_access         { $$ = $<node>1; }
	| variable              { $$ = $<node>1; }
	| literal               { $$ = $<node>1; }
	| expr_in_parens        { $$ = $<node>1; }
	;

/* Block definition */
block:
	'{' opt_nl block_args '|' opt_nl
		statements
	opt_nl '}' {
		NSError *err = nil;
		$$ = [TQNodeBlock node];
		for(TQNodeArgumentDef *arg in $3) {
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
	  identifier opt_nl {
		TQNodeArgumentDef *arg = [TQNodeArgumentDef nodeWithLocalName:[$1 value] identifier:nil];
		$$ = [NSMutableArray arrayWithObjects:arg, nil];
	} 
	| block_args ',' identifier opt_nl {
		TQNodeArgumentDef *arg = [TQNodeArgumentDef nodeWithLocalName:[$3 value] identifier:nil];
		[$$ addObject:arg];
	}
	;

/* Block call */
call:
	  callee '(' ')' { $$ = [TQNodeCall nodeWithCallee:$1]; }
	| callee '(' call_args ')' {
		$$ = [TQNodeCall nodeWithCallee:$1];
		[$$ setArguments:$3];
	}
	;
call_args:
	 call_arg opt_nl {
		TQNodeArgument *arg = [TQNodeArgument nodeWithPassedNode:$1 identifier:nil];
		$$ = [NSMutableArray arrayWithObjects:arg, nil];
	}
	| call_args ',' call_arg opt_nl {
		TQNodeArgument *arg = [TQNodeArgument nodeWithPassedNode:$3 identifier:nil];
		[$$ addObject:arg];
	}
	;
call_arg:
	  block              { $$ = $<node>1; }
	| call               { $$ = $<node>1; }
	| message_unterminated                { $$ = $<node>1; }
	| lhs '=' call_arg   { $$ = [TQNodeBinaryOperator nodeWithType:'=' left:$1 right:$3]; }
	| member_access      { $$ = $<node>1; }
	| variable           { $$ = $<node>1; }
	| literal            { $$ = $<node>1; }
	| expr_in_parens     { $$ = $<node>1; }

	;

/* Class definition */
class: '#' class_def opt_nl '{' opt_nl
	      methods opt_nl
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
	|  '#' class_def opt_nl '{' opt_nl
	   '}' {
		NSError *err = nil;
		$$ = [TQNodeClass nodeWithName:[[$2 objectAtIndex:0] value]
		                    superClass:[$2 count] == 2 ? [[$2 objectAtIndex:1] value] : nil
		                         error:&err];
		if(err)
			yyerror(&yylloc, state, [[err localizedDescription] UTF8String]);
	}
	;
class_def: constant '<' constant { $$ = [NSMutableArray arrayWithObjects:$1, $3, nil]; }
	| constant                   { $$ = [NSMutableArray arrayWithObjects:$1, nil]; }
	;

methods: method             { $$ = [NSMutableArray arrayWithObjects:$1, nil]; }
	| methods opt_nl method { [$$ addObject:$3]; }
	;
method: class_method
	| instance_method
	;
class_method:    '+' method_def { $$ = $2; [$$ setType:kTQClassMethod]; }
	;
instance_method: '-' method_def { $$ = $2; [$$ setType:kTQInstanceMethod]; }
	;
method_def: identifier method_args method_body {
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
	| identifier method_body {
		NSError *err = nil;
		$$ = [TQNodeMethod node];
		TQNodeArgumentDef *arg = [TQNodeArgumentDef nodeWithLocalName:nil identifier:[$1 value]];
		[$$ addArgument:arg error:&err];
		if(err)
			yyerror(&yylloc, state, [[err localizedDescription] UTF8String]);
		[$$ setStatements:$2];
	}
	;
method_args:
	  ':' identifier opt_nl {
		TQNodeArgumentDef *arg = [TQNodeArgumentDef nodeWithLocalName:[$2 value] identifier:nil];
		$$ = [NSMutableArray arrayWithObjects:arg, nil];
	} 
	| method_args ':' identifier opt_nl {
		TQNodeArgumentDef *arg = [TQNodeArgumentDef nodeWithLocalName:[$3 value] identifier:nil];
		[$$ addObject:arg];
	}
	| method_args identifier ':' identifier opt_nl {
		TQNodeArgumentDef *arg = [TQNodeArgumentDef nodeWithLocalName:[$4 value] identifier:[$2 value]];
		[$$ addObject:arg];
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
message_unterminated:
	  message_receiver identifier ':' opt_nl message_args {
		$$ = [TQNodeMessage nodeWithReceiver:$1];
		[[$5 objectAtIndex:0] setIdentifier:[$2 value]];
		[$$ setArguments:$5];
	}
	| message_receiver identifier  {
		$$ = [TQNodeMessage nodeWithReceiver:$1];
		TQNodeArgument *arg = [TQNodeArgument nodeWithPassedNode:nil identifier:[$2 value]];
		NSMutableArray *args = [NSMutableArray arrayWithObjects:arg, nil];
		[$$ setArguments:args];
	}
	;
message: message_unterminated term
	;

message_arg:
	  block                 { $$ = $<node>1; }
	| call                  { $$ = $<node>1; }
	| message               { $$ = $<node>1; }
	| lhs '=' message_arg   { $$ = [TQNodeBinaryOperator nodeWithType:'=' left:$1 right:$3]; }
	| member_access         { $$ = $<node>1; }
	| variable              { $$ = $<node>1; }
	| literal               { $$ = $<node>1; }
	| expr_in_parens        { $$ = $<node>1; }
	;

message_receiver:
	  member_access      { $$ = $<node>1; }
	| call               { $$ = $<node>1; }
	| variable           { $$ = $<node>1; }
	| literal
	| expr_in_parens        { $$ = $<node>1; }
	;
message_args:
	 message_args ':' message_arg {
		TQNodeArgument *arg = [TQNodeArgument nodeWithPassedNode:$3 identifier:nil];
		[$$ addObject:arg];
	}
	| message_arg {
		TQNodeArgument *arg = [TQNodeArgument nodeWithPassedNode:$1 identifier:nil];
		$$ = [NSMutableArray arrayWithObjects:arg, nil];
	}
	;


/* Basics */

opt_nl:
	| opt_nl '\n'
	;

/*opt_dot:*/
	/*| '.'*/
	/*;*/

term:
	  '\n'
	| '.'
	;

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

constant: tCONSTANT     {  $$ = [TQNodeIdentifier nodeWithCString:$1]; }
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
	TQParserState state = { [TQProgram programWithName:@"Test"], nil };
	yydebug = 5;
	yyparse(&state);
	NSLog(@"------------------------------------------");
	NSLog(@"%@", state.program);
	NSLog(@"------------------------------------------");
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
