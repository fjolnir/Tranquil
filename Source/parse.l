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
\\[^\r\n]*                          { UPDATE_LOC }
\/((\\\/)|[^\/])*\/[im]*                     {
                                        UPDATE_LOC
                                        yylval->cStr = strndup(yytext, yyleng);
                                        return tREGEX;
                                    }
(super)                             { UPDATE_LOC return tSUPER; }
(self)                              { UPDATE_LOC return tSELF;  }
(if)                                { UPDATE_LOC return tIF;    }
(else)                              { UPDATE_LOC return tELSE;  }
(while)                             { UPDATE_LOC return tWHILE; }
(until)                             { UPDATE_LOC return tUNTIL; }
(break)                             { UPDATE_LOC return tBREAK; }
(skip)                              { UPDATE_LOC return tSKIP;  }
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
(=>)                                {
                                        UPDATE_LOC
                                        return tMAPPINGOP;
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

[.\,=\.:\{\}\(\)\|<>\#\+\-\*\/\^`\[\]]  { UPDATE_LOC return *yytext; }
\n                                  { RESET_COL  return *yytext; }
%%

