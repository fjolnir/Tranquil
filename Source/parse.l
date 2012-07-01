%{
	#include <Tranquil.h>
	#include <stdlib.h>
	#include "y.tab.h"
	#define UPDATE_LOC { yylloc->first_line = yylloc->last_line = yylineno; yylloc->last_column += yyleng; }
	#define RESET_COL { yylloc->last_column = 0; }
%}

/*%option reentrant*/
%option yylineno
%option bison-bridge
%option bison-locations

%%
\\[^\r\n]*                          { /* Do nothing */ }
\.?[0-9]+(\.[0-9]+)?(e[0-9]+)?      {
                                    	UPDATE_LOC
                                    	yylval->dbl = atof(yytext);
                                    	return tNUMBER;
                                    }
\"[^\"]*\"|'[^']'                   {
                                    	UPDATE_LOC
                                    	yylval->cStr = strndup(yytext+1, yyleng-2);
                                    	return tSTRING;
                                    }
[a-z_][a-zA-Z_0-9]*                 {
                                    	UPDATE_LOC
                                    	yylval->cStr = strndup(yytext, yyleng);
                                    	return tIDENTIFIER;
                                    }
[A-Z][a-zA-Z_0-9]*                  {
                                    	UPDATE_LOC
                                    	yylval->cStr = strndup(yytext, yyleng);
                                    	return tCONSTANT;
                                    }
(<=)                                {
                                    	UPDATE_LOC
                                    	return tLESSEROREQUALOP;
                                    }
(>=)                                {
                                    	UPDATE_LOC
                                    	return tGREATEROREQUALOP;
                                    }
(==)                                {
                                    	UPDATE_LOC
                                    	return tEQUALOP;
                                    }
(!=)                                {
                                    	UPDATE_LOC
                                    	return tINEQUALOP;
                                    }

[.\,=\.:\{\}\(\)\|<>\#\+\-\*\/\^`]  { UPDATE_LOC return *yytext; }
\n                                  { RESET_COL  return *yytext; }
%%

