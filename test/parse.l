%{
	#include <Foundation/Foundation.h>
	#include "TQSyntaxTree.h"
	#include <stdlib.h>
	#include "y.tab.h"
%}

%%
\\[^\r\n]*                          { /* Do nothing */ }
\class                              { return tCLASS; }
\end                                { return tEND; }
\.?[0-9]+(\.[0-9]+)?(e[0-9]+)?      {
                                    	return tNUMBER;
                                    }
\"[^\"]*\"|'[^']'                   {
                                    	
                                    	return tSTRING;
                                    }
[a-zA-Z_][a-zA-Z_0-9]*              {
                                    
                                    	return tIDENTIFIER;
                                    }
[.=\.:\n\{\}\(\)\|<>+-]             { printf("> Other: %c\n", *yytext); return *yytext; }
%%

