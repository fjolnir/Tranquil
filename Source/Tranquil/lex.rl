#include "parse.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#import <Tranquil/CodeGen/TQNodeBlock.h>

typedef struct {
    int currentLine;
    TQNodeRootBlock *root;
} TQParserState;

#define NSStr(lTrim, rTrim) (ts ? [[[NSMutableString alloc] initWithBytes:ts+(lTrim) length:te-ts-(lTrim)-(rTrim) encoding:NSUTF8StringEncoding] autorelease] : nil)

#define CopyCStr() ((unsigned char *)strndup((char *)ts, te-ts))

#define _EmitToken(tokenId, val) do { \
    /*NSLog(@"emitting %d = %@", tokenId, val);*/ \
    Parse(parser, tokenId, [TQToken withId:tokenId value:val], &parserState); \
} while(0);

#define EmitToken(tokenId) EmitStringToken(tokenId, 0, 0)

#define EmitStringToken(tokenId, lTrim, rTrim) _EmitToken(tokenId, NSStr(lTrim, rTrim))

#define EmitIntToken(tokenId, base, prefixLen) do { \
    unsigned char *str = CopyCStr(); \
    long long numVal = strtoll((char *)str + (prefixLen), NULL, (base)); \
    _EmitToken((tokenId), [NSNumber numberWithLongLong:numVal]); \
    free(str); \
} while(0)

#define EmitFloatToken(tokenId) do { \
    unsigned char *str = CopyCStr(); \
    _EmitToken((tokenId), [NSNumber numberWithDouble:atof((char *)str)]); \
    free(str); \
} while(0)

#define BacktrackTerm() do { \
    if(*p == '}') --p; \
} while(0)


@interface TQToken : NSObject
@property(readwrite, assign) int id;
@property(readwrite, strong) id value;
+ (TQToken *)withId:(int)id value:(id)value;
@end
@implementation TQToken
+ (TQToken *)withId:(int)id value:(id)value
{
    TQToken *ret = [self new];
    ret.id = id;
    ret.value = value;
    return [ret autorelease];
}
@end

%%{
    machine Tranquil;
    alphtype unsigned char;
    include WChar "utf8.rl";

    int         = udigit+;
    float       = (udigit+)? '.' udigit+;
    hex         = "0x"i xdigit+;
    bin         = "0b"i [0-1]+;
    oct         = "0o"i [0-7]+;

    char        = ualnum | '?' | '!' | '_';
    constant    = '_'* uupper char*;
    identifier  = '_'* ulower char*;
    comment     = '\\' [^\n]*;
    nl          = ((space|comment)* '\n' space*);
    whitespace  = (nl|space|comment);
    whitespaceNoNl  = (" "|"\t"|comment);
    term        = whitespace* (nl|"}"|".");

    lGuillmt    = 0xC2 0xAB; # «
    rGuillmt    = 0xC2 0xBB; # »

    strCont     = (ualnum | ascii) - '"';
    string      = '"' strCont* '"';
    constStr    = "@" (string | [^\n ;,\]}.)`]+);
    lStr        = '"' strCont* lGuillmt;
    mStr        = rGuillmt strCont* lGuillmt;
    rStr        = rGuillmt strCont* '"';
    selector    = (ualnum | "+" | "-" | "*" | "/" | "^" | "=" | "~" | "<" | ">" | "[" | "]" | "_")+ ":";
    #(constant | identifier | "+" | "-" | "*" | "/" | "^" | "==" | "~=" | "<=" | ">=" | "=" | "[" | "]")? ':';


main := |*
# Symbols
    "{"                              => { EmitToken(LBRACE);                                              };
    "}" term                         => { EmitToken(RBRACENL);   BacktrackTerm();                         };
    "}"                              => { EmitToken(RBRACE);                                              };
    "["                              => { EmitToken(LBRACKET);                                            };
    "]" term                         => { EmitToken(RBRACKETNL); BacktrackTerm();                         };
    "]"                              => { EmitToken(RBRACKET);                                            };
    "("                              => { EmitToken(LPAREN);                                              };
    ")" term                         => { EmitToken(RPARENNL);   BacktrackTerm();                         };
    ")"                              => { EmitToken(RPAREN);                                              };
    ","                              => { EmitToken(COMMA);                                               };
    "`" term                         => { EmitToken(BACKTICKNL); BacktrackTerm();                         };
    "`"                              => { EmitToken(BACKTICK);                                            };
    ";"                              => { EmitToken(SEMICOLON);                                           };
    "="                              => { EmitToken(ASSIGN);                                              };
    "+="                             => { EmitToken(ASSIGNADD);                                           };
    "-="                             => { EmitToken(ASSIGNSUB);                                           };
    "*="                             => { EmitToken(ASSIGNMUL);                                           };
    "/="                             => { EmitToken(ASSIGNDIV);                                           };
    "||="                            => { EmitToken(ASSIGNOR);                                            };
    "+"                              => { EmitToken(PLUS);                                                };
    "-"                              => { EmitToken(MINUS);                                               };
    "--"                             => { EmitToken(DECR);                                                };
    "--" term                        => { EmitToken(DECRNL);     BacktrackTerm();                         };
    "++"                             => { EmitToken(INCR);                                                };
    "++" term                        => { EmitToken(INCRNL);     BacktrackTerm();                         };
    "*"                              => { EmitToken(ASTERISK);                                            };
    "/"                              => { EmitToken(FSLASH);                                              };
    "%"                              => { EmitToken(PERCENT);                                             };
    "~"                              => { EmitToken(TILDE);                                               };
    "#"                              => { EmitToken(HASH);                                                };
    "|"                              => { EmitToken(PIPE);                                                };
    "^"                              => { EmitToken(CARET);                                               };
    "?"                              => { EmitToken(TERNIF);                                              };
    "!"                              => { EmitToken(TERNELSE);                                            };
    "=="                             => { EmitToken(EQUAL);                                               };
    "~="                             => { EmitToken(INEQUAL);                                             };
    "<"                              => { EmitToken(LESSER);                                              };
    ">"                              => { EmitToken(GREATER);                                             };
    "<="                             => { EmitToken(LEQUAL);                                              };
    ">="                             => { EmitToken(GEQUAL);                                              };
    "=>"                             => { EmitToken(DICTSEP);                                             };

# Message selectors
    selector                         => { EmitStringToken(SELPART, 0, 1);                                 };

# Keywords
    "if"      term?                  => { EmitToken(IF); BacktrackTerm();                                 };
    "unless"  term?                  => { EmitToken(UNLESS); BacktrackTerm();                             };
    "then"    term?                  => { EmitToken(THEN); BacktrackTerm();                               };
    "else"    term?                  => { EmitToken(ELSE); BacktrackTerm();                               };
    "and"|"&&"term?                  => { EmitToken(AND); BacktrackTerm();                                };
    "or"|"||" term?                  => { EmitToken(OR); BacktrackTerm();                                 };
    "while"   term?                  => { EmitToken(WHILE); BacktrackTerm();                              };
    "until"   term?                  => { EmitToken(UNTIL); BacktrackTerm();                              };
    "import"  term?                  => { EmitToken(IMPORT); BacktrackTerm();                             };
    "async"   term?                  => { EmitToken(ASYNC); BacktrackTerm();                              };
    "wait"    term                   => { EmitToken(WAITNL); BacktrackTerm();                             };
    "wait"                           => { EmitToken(WAIT);                                                };
    "lock"                           => { EmitToken(LOCK);                                                };
    "whenFinished"                   => { EmitToken(WHENFINISHED);                                        };
    "collect"                        => { EmitToken(COLLECT);                                             };
    "break"   term                   => { EmitToken(BREAKNL); BacktrackTerm();                            };
    "break"                          => { EmitToken(BREAK);                                               };
    "skip"    term                   => { EmitToken(SKIPNL);  BacktrackTerm();                            };
    "skip"                           => { EmitToken(SKIP);                                                };
    "self"    term                   => { EmitToken(SELFNL); BacktrackTerm();                             };
    "super"   term                   => { EmitToken(SUPERNL); BacktrackTerm();                            };
    "..."     term                   => { EmitToken(VAARGNL); BacktrackTerm();                            };
    "nil"     term                   => { EmitToken(NILNL); BacktrackTerm();                              };
    "valid"   term                   => { EmitToken(VALIDNL); BacktrackTerm();                            };
    "yes"     term                   => { EmitToken(YESTOKNL); BacktrackTerm();                           };
    "no"      term                   => { EmitToken(NOTOKNL); BacktrackTerm();                            };
    "nothing" term                   => { EmitToken(NOTHINGNL); BacktrackTerm();                          };
    "self"                           => { EmitToken(SELF);                                                };
    "super"                          => { EmitToken(SUPER);                                               };
    "..."                            => { EmitToken(VAARG);                                               };
    "nil"                            => { EmitToken(NIL);                                                 };
    "valid"                          => { EmitToken(VALID);                                               };
    "yes"                            => { EmitToken(YESTOK);                                              };
    "no"                             => { EmitToken(NOTOK);                                               };
    "nothing"                        => { EmitToken(NOTHING);                                             };


# Identifiers
    identifier %{temp1 = p;} term    => { te = temp1; EmitStringToken(IDENTNL, 0, 0); BacktrackTerm();    };
    identifier                       => { EmitStringToken(IDENT,   0, 0);                                 };

    constant   %{temp1 = p;} term    => { te = temp1; EmitStringToken(CONSTNL, 0, 0); BacktrackTerm();    };
    constant                         => { EmitStringToken(CONST,   0, 0);                                 };

# Literals
    int   term                       => { EmitIntToken(NUMBERNL, 10, 0); BacktrackTerm();                 };
    float term                       => { EmitFloatToken(NUMBERNL);      BacktrackTerm();                 };
    bin   term                       => { EmitIntToken(NUMBERNL, 2,  2); BacktrackTerm();                 };
    oct   term                       => { EmitIntToken(NUMBERNL, 8,  2); BacktrackTerm();                 };
    hex   term                       => { EmitIntToken(NUMBERNL, 16, 2); BacktrackTerm();                 };

    int                              => { EmitIntToken(NUMBER, 10, 0);                                    };
    float                            => { EmitFloatToken(NUMBER);                                         };
    bin                              => { EmitIntToken(NUMBER, 2,  2);                                    };
    oct                              => { EmitIntToken(NUMBER, 8,  2);                                    };
    hex                              => { EmitIntToken(NUMBER, 16, 2);                                    };

    constStr %{temp1 = p;} term      => { te = temp1; EmitStringToken(CONSTSTRNL,  1, 0); BacktrackTerm();};
    constStr                         => { EmitStringToken(CONSTSTR,    1, 0);                             };

    lStr                             => { EmitStringToken(LSTR,   1, 2);                                  };
    mStr                             => { EmitStringToken(MSTR,   2, 2);                                  };
    rStr   %{temp1 = p;} term        => { te = temp1; EmitStringToken(RSTRNL, 2, 1); BacktrackTerm();     };
    rStr                             => { EmitStringToken(RSTR,   2, 1);                                  };
    string %{temp1 = p;} term        => { te = temp1; EmitStringToken(STRNL,  1, 1); BacktrackTerm();     };
    string                           => { EmitStringToken(STR,    1, 1);                                  };

    nl;
    space;
*|;

}%%

%% write data nofinal;

#include "parse.mm"

extern "C" TQNode *TQParseString(NSString *str)
{
    if(![str hasSuffix:@"\n"])
        str = [str stringByAppendingString:@"\n"];

    int cs, act;
    unsigned char *ts, *te = 0;

    // Lexer setup
    unsigned char *p = (unsigned char *)[str UTF8String];
    unsigned char *pe = p + strlen((char*)p);
    unsigned char *eof = pe;

    unsigned char *temp1, *temp2;

    // Parser setup
    void *parser = ParseAlloc(malloc);
    TQParserState parserState = {
        0, [TQNodeRootBlock new]
    };

    %% write init;
    %% write exec;

    if(p != pe)
        fprintf(stderr, "invalid character '%c'\n", p[0]);

    EmitToken(0); // EOF
    ParseFree(parser, free);
    return [parserState.root autorelease];
}
