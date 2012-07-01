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
                                    	yylval.number = [[TQSyntaxNodeNumber alloc] init];
										NSNumber *num = [[NSNumber alloc] initWithDouble:atof(yytext)];
										yylval.number.value = num;
										[num release];
										NSLog(@"Num: %@\n", yylval.number);
                                    	return tNUMBER;
                                    }
\"[^\"]*\"|'[^']'                   {
                                    	yylval.string = [[TQSyntaxNodeString alloc] init];
                                    	NSString *str = [[NSString alloc] initWithBytesNoCopy:yytext+1 length:yylen-2
                                    	                                             encoding:NSUTF8StringEncoding freeWhenDone:NO];
                                    	yylval.string.value = str;
                                    	[str release];
                                    	NSLog(@"> String: %@", yylval.string);
                                    	return tSTRING;
                                    }
[a-zA-Z_][a-zA-Z_0-9]*              {
                                    	yylval.string = [[TQSyntaxNodeString alloc] init];
                                    	NSString *str = [[NSString alloc] initWithBytesNoCopy:yytext length:yylen
                                    	                                             encoding:NSUTF8StringEncoding freeWhenDone:NO];
                                    	yylval.string.value = str;
                                    	[str release];
                                    	NSLog(@"> Id: %@", yylval.string);
                                    	return tIDENTIFIER;
                                    }
[.=\.:\n\{\}\(\)\|<>+-]             { printf("> Other: %c\n", *yytext); return *yytext; }
%%

