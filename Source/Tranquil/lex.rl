#include "parse.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#import <Tranquil/CodeGen/TQNodeBlock.h>

typedef struct {
    int currentLine;
    BOOL atBeginningOfExpr;
    TQNodeRootBlock *root;
} TQParserState;

#define NSStr(lTrim, rTrim) (ts ? [[[NSMutableString alloc] initWithBytes:ts+(lTrim) length:te-ts-(lTrim)-(rTrim) encoding:NSUTF8StringEncoding] autorelease] : nil)

#define CopyCStr() ((unsigned char *)strndup((char *)ts, te-ts))

#define _EmitToken(tokenId, val) do { \
    /*NSLog(@"emitting %d = %@ on line: %d", tokenId, val, parserState.currentLine);*/ \
    Parse(parser, tokenId, [TQToken withId:tokenId value:val line:parserState.currentLine], &parserState); \
    parserState.atBeginningOfExpr = NO; \
} while(0);

#define EmitToken(tokenId) EmitStringToken((tokenId), 0, 0)

#define EmitStringToken(tokenId, lTrim, rTrim) _EmitToken(tokenId, NSStr(lTrim, rTrim))

#define EmitConstStringToken(tokenId, lTrim, rTrim) do { \
    BOOL hasQuotes = *(ts+1) == '"'; \
    EmitStringToken((tokenId), lTrim+1+hasQuotes, rTrim+hasQuotes); \
} while(0)

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

#define IncrementLine() (++parserState.currentLine)

#define BacktrackTerm() do { \
    if(*p == '}') \
        --p; \
    for(unsigned char *cursor = ts; cursor != te; ++cursor) { \
        if(*cursor == '\n') \
            IncrementLine(); \
    } \
} while(0)

#define ExprBeg() parserState.atBeginningOfExpr = YES

@interface TQToken : NSObject
@property(readwrite, assign) int id, line;
@property(readwrite, strong) id value;
+ (TQToken *)withId:(int)id value:(id)value line:(int)line;
@end
@implementation TQToken
+ (TQToken *)withId:(int)id value:(id)value line:(int)line
{
    TQToken *ret = [self new];
    ret.id = id;
    ret.value = value;
    ret.line = line;
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
    anybase     = udigit+ "r"i ([0-9]|[a-zA-Z])+;

    char        = ualnum | '?' | '!' | '_';
    constant    = '_'* uupper char*;
    identifier  = '_'* ulower char*;
    comment     = '\\' [^\n]*;
    nl          = ((space|comment)* '\n' space*);
    whitespace  = (nl|space|comment);
    whitespaceNoNl  = (" "|"\t"|comment);
    term        = whitespace* (nl|"}");

    lGuillmt    = 0xC2 0xAB; # «
    rGuillmt    = 0xC2 0xBB; # »

    strCont     = (ualnum | ascii) - '"';
    simpleStr   = '"' strCont* '"';
    constStr    = "@" (simpleStr | [^\n ;,\]}.)`]+);
    selector    = (ualnum | "+" | "-" | "*" | "/" | "^" | "=" | "~" | "<" | ">" | "[" "]" | "_")* ":";

    regexCont   = (ualnum | ascii) - '/';

string := |*
    '\\n'                            => { [strBuf appendString:@"\n"];                                    };
    '\\t'                            => { [strBuf appendString:@"\t"];                                    };
    '\\r'                            => { [strBuf appendString:@"\r"];                                    };
    '\\"'                            => { [strBuf appendString:@"\""];                                    };
    "\\'"                            => { [strBuf appendString:@"'"];                                     };
    "\\\\"                           => { [strBuf appendString:@"\\"];                                    };
    '\\x' %{ temp1 = p; } [0-9a-zA-Z]* => {
        long long code = strtoll((char*)temp1, NULL, 16);
        [strBuf appendFormat:@"%c", (int)code];
    };
    "\\" ualnum+                     => { TQAssert(NO, @"Invalid escape %@", NSStr(0,0));                 };
    strCont                          => { [strBuf appendString:NSStr(0, 0)];                              };

    lGuillmt                         => { _EmitToken(temp3 == 1 ? LSTR  : MSTR, strBuf); fret;            };
    '"' term                         => { _EmitToken(temp3 == 1 ? STRNL : RSTRNL, strBuf); fret;          };
    '"'                              => { _EmitToken(temp3 == 1 ? STR   : RSTR, strBuf); fret;            };
*|;

regex := |*
    regexCont* "/" [im]* term        => { --ts; EmitToken(REGEXNL); BacktrackTerm(); fret;               };
    regexCont* "/" [im]*             => { --ts; EmitToken(REGEX);                    fret;               };
*|;

main := |*
# Symbols
 # Forward slash is context sensitive, at the beginning of an expression it means the start of a regular expression
    "/"                              => {
        if(!parserState.atBeginningOfExpr) {
            if(p != eof && *(p+1) == '=') {
                EmitToken(ASSIGNDIV);
                p += 2;
            } else
                EmitToken(FSLASH);
            ExprBeg();
        } else
            fcall regex;
    };
    "{"                              => { EmitToken(LBRACE);     ExprBeg();                               };
    "}" term                         => { EmitToken(RBRACENL);   ExprBeg(); BacktrackTerm();              };
    "}"                              => { EmitToken(RBRACE);                                              };
    "["                              => { EmitToken(LBRACKET);   ExprBeg();                               };
    "]" term                         => { EmitToken(RBRACKETNL); ExprBeg(); BacktrackTerm();              };
    "]"                              => { EmitToken(RBRACKET);                                            };
    "("                              => { EmitToken(LPAREN);     ExprBeg();                               };
    ")" term                         => { EmitToken(RPARENNL);   ExprBeg(); BacktrackTerm();              };
    ")"                              => { EmitToken(RPAREN);                                              };
    ","                              => { EmitToken(COMMA);      ExprBeg();                               };
    "`" term                         => { EmitToken(BACKTICKNL); BacktrackTerm();                         };
    "`"                              => { EmitToken(BACKTICK);                                            };
    ";"                              => { EmitToken(SEMICOLON);                                           };
    "="                              => { EmitToken(ASSIGN);     ExprBeg();                               };
    "+="                             => { EmitToken(ASSIGNADD);  ExprBeg();                               };
    "-="                             => { EmitToken(ASSIGNSUB);  ExprBeg();                               };
    "*="                             => { EmitToken(ASSIGNMUL);  ExprBeg();                               };
#    "/="                             => { EmitToken(ASSIGNDIV);  ExprBeg();                               };
    "||="                            => { EmitToken(ASSIGNOR);   ExprBeg();                               };
    "+"                              => { EmitToken(PLUS);       ExprBeg();                               };
    "-"                              => { EmitToken(MINUS);      ExprBeg();                               };
    "--"                             => { EmitToken(DECR);                                                };
    "--" term                        => { EmitToken(DECRNL);     ExprBeg();BacktrackTerm();               };
    "++"                             => { EmitToken(INCR);                                                };
    "++" term                        => { EmitToken(INCRNL);     ExprBeg();BacktrackTerm();               };
    "*"                              => { EmitToken(ASTERISK);   ExprBeg();                               };
    "%"                              => { EmitToken(PERCENT);    ExprBeg();                               };
    "~"                              => { EmitToken(TILDE);      ExprBeg();                               };
    "#"                              => { EmitToken(HASH);                                                };
    "|"                              => { EmitToken(PIPE);       ExprBeg();                               };
    "^"                              => { EmitToken(CARET);      ExprBeg();                               };
    "?"                              => { EmitToken(TERNIF);     ExprBeg();                               };
    "!"                              => { EmitToken(TERNELSE);   ExprBeg();                               };
    "=="                             => { EmitToken(EQUAL);      ExprBeg();                               };
    "!="                             => { EmitToken(INEQUAL);    ExprBeg();                               };
    "~="                             => { EmitToken(INEQUAL);    ExprBeg();                               };
    "<"                              => { EmitToken(LESSER);     ExprBeg();                               };
    ">"                              => { EmitToken(GREATER);    ExprBeg();                               };
    "<="                             => { EmitToken(LEQUAL);     ExprBeg();                               };
    ">="                             => { EmitToken(GEQUAL);     ExprBeg();                               };
    "=>"                             => { EmitToken(DICTSEP);    ExprBeg();                               };

# Message selectors
    selector                         => { EmitStringToken(SELPART, 0, 1); ExprBeg();                      };

# Keywords
    "if"      term?                  => { EmitToken(IF);        ExprBeg(); BacktrackTerm();               };
    "unless"  term?                  => { EmitToken(UNLESS);    ExprBeg(); BacktrackTerm();               };
    "then"    term?                  => { EmitToken(THEN);      ExprBeg(); BacktrackTerm();               };
    "else"    term?                  => { EmitToken(ELSE);      ExprBeg(); BacktrackTerm();               };
    "and"|"&&"term?                  => { EmitToken(AND);       ExprBeg(); BacktrackTerm();               };
    "or"|"||" term?                  => { EmitToken(OR);        ExprBeg(); BacktrackTerm();               };
    "while"   term?                  => { EmitToken(WHILE);     ExprBeg(); BacktrackTerm();               };
    "until"   term?                  => { EmitToken(UNTIL);     ExprBeg(); BacktrackTerm();               };
    "import"  term?                  => { EmitToken(IMPORT);    ExprBeg(); BacktrackTerm();               };
    "async"   term?                  => { EmitToken(ASYNC);     ExprBeg(); BacktrackTerm();               };
    "wait"    term                   => { EmitToken(WAITNL);    ExprBeg(); BacktrackTerm();               };
    "wait"                           => { EmitToken(WAIT);                                                };
    "lock"                           => { EmitToken(LOCK);                                                };
    "whenFinished"                   => { EmitToken(WHENFINISHED);                                        };
    "collect"                        => { EmitToken(COLLECT);                                             };
    "break"   term                   => { EmitToken(BREAKNL);   ExprBeg(); BacktrackTerm();               };
    "break"                          => { EmitToken(BREAK);                                               };
    "skip"    term                   => { EmitToken(SKIPNL);    ExprBeg(); BacktrackTerm();               };
    "skip"                           => { EmitToken(SKIP);                                                };
    "self"    term                   => { EmitToken(SELFNL);    ExprBeg(); BacktrackTerm();               };
    "super"   term                   => { EmitToken(SUPERNL);   ExprBeg(); BacktrackTerm();               };
    "..."     term                   => { EmitToken(VAARGNL);   ExprBeg(); BacktrackTerm();               };
    "nil"     term                   => { EmitToken(NILNL);     ExprBeg(); BacktrackTerm();               };
    "valid"   term                   => { EmitToken(VALIDNL);   ExprBeg(); BacktrackTerm();               };
    "yes"     term                   => { EmitToken(YESTOKNL);  ExprBeg(); BacktrackTerm();               };
    "no"      term                   => { EmitToken(NOTOKNL);   ExprBeg(); BacktrackTerm();               };
    "nothing" term                   => { EmitToken(NOTHINGNL); ExprBeg(); BacktrackTerm();               };
    "self"                           => { EmitToken(SELF);                                                };
    "super"                          => { EmitToken(SUPER);                                               };
    "..."                            => { EmitToken(VAARG);                                               };
    "nil"                            => { EmitToken(NIL);                                                 };
    "valid"                          => { EmitToken(VALID);                                               };
    "yes"                            => { EmitToken(YESTOK);                                              };
    "no"                             => { EmitToken(NOTOK);                                               };
    "nothing"                        => { EmitToken(NOTHING);                                             };


# Identifiers
    identifier %{temp1 = p;} term    => { EmitStringToken(IDENTNL, 0, te-temp1); ExprBeg(); BacktrackTerm(); };
    identifier                       => { EmitStringToken(IDENT,   0, 0);                                 };

    constant   %{temp1 = p;} term    => { EmitStringToken(CONSTNL, 0, te-temp1); ExprBeg(); BacktrackTerm(); };
    constant                         => { EmitStringToken(CONST,   0, 0);                                 };

# Literals
    int   term                       => { EmitIntToken(NUMBERNL, 10, 0); ExprBeg(); BacktrackTerm();      };
    float term                       => { EmitFloatToken(NUMBERNL);      ExprBeg(); BacktrackTerm();      };
    bin   term                       => { EmitIntToken(NUMBERNL, 2,  2); ExprBeg(); BacktrackTerm();      };
    oct   term                       => { EmitIntToken(NUMBERNL, 8,  2); ExprBeg(); BacktrackTerm();      };
    hex   term                       => { EmitIntToken(NUMBERNL, 16, 2); ExprBeg(); BacktrackTerm();      };
    anybase term                     => {
        // Find the base
        NSString *str = NSStr(0,0);
        NSString *baseStr = [str substringToIndex:[str rangeOfString:@"r"].location];
        EmitIntToken(NUMBERNL, atoi([baseStr UTF8String]), [baseStr length]+1); ExprBeg(); BacktrackTerm();
    };

    int                              => { EmitIntToken(NUMBER, 10, 0);                                    };
    float                            => { EmitFloatToken(NUMBER);                                         };
    bin                              => { EmitIntToken(NUMBER, 2,  2);                                    };
    oct                              => { EmitIntToken(NUMBER, 8,  2);                                    };
    hex                              => { EmitIntToken(NUMBER, 16, 2);                                    };

    constStr %{temp1 = p;} term      => { EmitConstStringToken(CONSTSTRNL, 0, te-temp1); ExprBeg(); BacktrackTerm(); };
    constStr                         => { EmitConstStringToken(CONSTSTR, 0, 0);                           };

    '"'                              => { temp3 = 1; strBuf = [NSMutableString string]; fcall string;     };
    rGuillmt                         => { temp3 = 2; strBuf = [NSMutableString string]; fcall string;     };

    nl                               => { IncrementLine();                                                };
    space;
*|;
}%%

%% write data nofinal;

#include "parse.mm"

extern "C" TQNode *TQParseString(NSString *str, NSError **aoErr)
{
    if(![str hasSuffix:@"\n"])
        str = [str stringByAppendingString:@"\n"];

    int cs, act;
    unsigned char *ts, *te = 0;

    // Lexer setup
    unsigned char *p = (unsigned char *)[str UTF8String];
    unsigned char *pe = p + strlen((char*)p);
    unsigned char *eof = pe;
    int top;
    int stack[1024];
    NSMutableString *strBuf;

    unsigned char *temp1, *temp2;
    int temp3 = 0;

    // Parser setup
    void *parser = ParseAlloc(malloc);
    TQParserState parserState = {
        1, YES, [TQNodeRootBlock new]
    };

    @try {
        %% write init;
        %% write exec;

        if(p != pe)
            fprintf(stderr, "invalid character '%c'\n", p[0]);

        EmitToken(0); // EOF
        return [parserState.root autorelease];
    } @catch(NSException *e) {
        if(aoErr)
            *aoErr = [NSError errorWithDomain:kTQSyntaxErrorDomain
                                         code:kTQGenericError
                                     userInfo:[NSDictionary dictionaryWithObject:[e reason] forKey:@"reason"]];
         return nil;
    } @finally {
        ParseFree(parser, free);
    }
    return nil;
}
