%{
	#include "TQNode.h"
	#include <stdlib.h>
	#include "y.tab.h"
%}

/*%option reentrant*/
%option yylineno
%option bison-bridge
%option bison-locations

%%
\\[^\r\n]*                          { /* Do nothing */ }
class                               { return tCLASS; }
end                                 { return tEND; }
return                              { return tRETURN; }
\.?[0-9]+(\.[0-9]+)?(e[0-9]+)?      {
                                    	yylval->dbl = atof(yytext);
                                    	return tNUMBER;
                                    }
\"[^\"]*\"|'[^']'                   {
                                    	yylval->cStr = strndup(yytext+1, yyleng-2);
                                    	return tSTRING;
                                    }
[a-zA-Z_][a-zA-Z_0-9]*              {
                                    	yylval->cStr = strndup(yytext, yyleng);
                                    	return tIDENTIFIER;
                                    }
[.=\.:\n\{\}\(\)\|<>\#+-]           { return *yytext; }
%%

