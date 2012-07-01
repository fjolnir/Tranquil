%debug

%union {
	double dbl;
	char *text;
}

%token <text> tLPAREN tRPAREN      // ()
%token <text> tLBRACE tRBRACE      // {}
%token <text> tLBRACKET tRBRACKET  // {}
%token <text> tPIPE                // |
%token <text> tCOLON               // :
%token <text> tSEMICOLON           // ;
%token <text> tDOT                 // .
%token <text> tCOMMA               // ,
%token <text> tASSIGN              // =
%token <dbl> tNUMBER        // <number>
%token <text> tSTRING       // Contents of a quoted string
%token <text> tIDENTIFIER   // An identifier, non quoted string matching [a-zA-Z0-9_]+

%type<text> var assignment assignee expr argDef literal block objAccess obj call assignmentExpr

%{
	#include <stdio.h>
	#include <stdlib.h>
%}

%%

%start program;
program:
	  | expr
	;

call:
	  expr tCOLON arg args tSEMICOLON
	| expr tCOLON arg tSEMICOLON
	| expr tSEMICOLON
	;
args:
	  tIDENTIFIER tCOLON arg
	| tCOLON arg
	;
arg:
	 expr

block:
	  tLBRACE argDefs tPIPE expr tRBRACE
	| tLBRACE expr tRBRACE
	;

argDefs:
	  argDef tIDENTIFIER tCOLON argDefs
	| argDef tCOLON argDefs
	| argDef
	;
argDef:
	  tIDENTIFIER

assignment:
	  assignee tASSIGN assignmentExpr { printf("%s = %s\n", $1, $3); }
	;
assignee:
	  var
	| objAccess
	;
assignmentExpr:
	 var
	| block
	/*| objAccess*/
	| obj
	| literal
	/*| call*/
	| tLPAREN assignmentExpr tRPAREN
	;
var:
	  tIDENTIFIER { printf("var: %s\n", $1); }
	;

expr:
	  assignment
	| var
	| block
	| objAccess
	| obj
	| literal
	| call
	| tLPAREN expr tRPAREN
	;

obj:
	  tLBRACKET objMembers tRBRACKET
	| tLBRACKET tRBRACKET
	;
objMembers:
	| objMembers tCOMMA objMembers
	| objMember
	;
objMember:
	  tIDENTIFIER tASSIGN expr
	;

objAccess:
	  var tDOT tIDENTIFIER
	;

literal:
	  tNUMBER  { printf("num %f\n", $1); }
	| tSTRING  { printf("str '%s'\n", $1); }
	;
%%

int yyerror(char *str)
{
	fprintf(stderr, "%s\n", str);
	exit(3);
	return 0;
}

int yywrap(void) {
	return 1;
}

int main()
{
yydebug = 1;
	yyparse();
	return 0;
}
