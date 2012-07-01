%union {
	double dbl;
	char *text;
}

%token <text> tLPAREN tRPAREN      /* () */
%token <text> tLBRACE tRBRACE      /* {} */
%token <text> tLBRACKET tRBRACKET  /* {} */
%token <text> tPIPE                /* | */
%token <text> tCOLON               /* : */
%token <text> tSEMICOLON           /* ; */
%token <text> tDOT                 /* . */
%token <text> tCOMMA               /* , */
%token <text> tASSIGN              /* = */
%token <text> tARROW               /* -> */
%token <text> tHASH                /* # */
%token <dbl> tNUMBER               /* <number> */
%token <text> tSTRING              /* Contents of a quoted string */
%token <text> tIDENTIFIER          /* An identifier, non quoted string matching [a-zA-Z0-9_]+ */

%type<text> variable assignment expression lhs literal object member_access
%start statements

%{
	#include <stdio.h>
	#include <stdlib.h>
	extern int yylineno;
	extern char* yytext;
%}

%%
assignment:
	  lhs tASSIGN expression  { printf("------ %s = %s\n", $1, $3); $$=malloc(128); sprintf($$, "%s=%s", $1, $3); }
	;

lhs:
	  member_access
	| variable
	;

variable:
	  tIDENTIFIER { printf("variable: %s\n", $1); $$=malloc(128); sprintf($$, "%s", $1); }
	;

statements:
	| statements statement
	;

statement:
	  message { printf("Message!\n"); }
	| call { printf("Call!\n"); }
	| assignment
	| tLPAREN statement tRPAREN

expression: { $$ = "expr"; }
	  object { printf("object!\n"); }
	| block { printf("Block!\n"); }
	| message { printf("Message!\n"); }
	| call { printf("Call!\n"); }
	| assignment
	| member_access
	| variable
	| literal
	| tLPAREN expression tRPAREN
	;

/* Block definition */
block:
	  tLBRACE block_args tPIPE statements tRBRACE
	| tLBRACE tPIPE statements tRBRACE
	| tLBRACE statements tRBRACE
	;
block_args:
	  tCOLON block_arg
	| block_args tCOLON block_arg
	| block_args block_arg_identifier tCOLON block_arg
	;
block_arg:
	  tIDENTIFIER { printf("arg var: %s\n", $1); }
	;
block_arg_identifier:
	  tIDENTIFIER { printf("arg name: %s\n", $1); }
	;

/* Block call */
call:
	  lhs tDOT
	| lhs call_args tDOT
	;
call_args:
	  tCOLON call_arg
	| call_args tCOLON call_arg
	| call_args block_arg_identifier tCOLON call_arg
	;
call_arg:
	  tIDENTIFIER { printf("arg var: %s\n", $1); } /* TODO: Make into expression */
	;



/* Object definition */
object:
	  tLBRACKET object_methods  tRBRACKET
	;
object_methods:
	| object_methods object_method
	;
object_method:
	  tIDENTIFIER tARROW block { printf("object member: %s\n", $1); }
	;

/* Object member access */
member_access:
	  lhs tHASH tIDENTIFIER { printf("objectacc: %s.%s\n", $1, $3); $$=malloc(128); sprintf($$, "%s.%s", $1, $3); }
	;
message:
	lhs call
	;

literal:
	  tNUMBER  { printf("num %f\n", $1); $$=malloc(128); sprintf($$, "%f", $1); }
	| tSTRING  { printf("str '%s'\n", $1); }
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
