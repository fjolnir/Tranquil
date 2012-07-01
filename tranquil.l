%{
	#include <stdlib.h>
	#include "y.tab.h"
	size_t len;
	char *buf;
%}

%%
\\[^\r\n]*                          { printf("> Comment"); }
\(                                  { yylval.text = "("; return tLPAREN; }
\)                                  { yylval.text = ")"; return tRPAREN; }
\{                                  { yylval.text = "{"; return tLBRACE; }
\}                                  { yylval.text = "}"; return tRBRACE; }
\[                                  { yylval.text = "["; return tLBRACKET; }
\]                                  { yylval.text = "]"; return tRBRACKET; }
\|                                  { yylval.text = "|"; return tPIPE; }
:                                   { yylval.text = ":"; return tCOLON; }
;                                   { yylval.text = ";"; return tSEMICOLON; }
\.                                  { yylval.text = "."; return tDOT; }
,                                   { yylval.text = ","; return tCOMMA; }
=                                   { yylval.text = "="; return tASSIGN; }
\->                                 { yylval.text = "->"; return tARROW; }
\#                                  { yylval.text = "#"; return tHASH; }
\<                                  { yylval.text = "<"; return tLESSTHAN; }
\>                                  { yylval.text = ">"; return tGREATERTHAN; }
\class                              { yylval.text ="class"; return tCLASS; }
\.?[0-9]+(\.[0-9]+)?(e[0-9]+)?      {
                                    	yylval.dbl = atof(yytext);
                                    	return tNUMBER;
                                    }
\"[^\"]*\"|'[^']'                   {
                                    	len = strlen(yytext) - 2; // Omit the quotes
                                    	buf = calloc(len + 1, sizeof(char));
                                    	strncpy(buf, yytext + sizeof(char), len);
                                    	yylval.text = buf;
										printf("> Str: %s\n", buf);
                                    	return tSTRING;
                                    }
[a-zA-Z_][a-zA-Z_0-9]*              {
                                    	buf = calloc(strlen(yytext)+1, sizeof(char));
                                    	strcpy(buf, yytext);
                                    	yylval.text = buf;
										printf("> Id: %s\n", buf);
                                    	return tIDENTIFIER;
                                    }
%%
		//.                                   { fprintf(stderr, "Unhandled: %c\n", *yytext); }

