#include "parse.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#import <Tranquil/CodeGen/TQNodeBlock.h>

enum {
    kTQStrTypeSimple,
    kTQStrTypeLeftOrMiddle,
    kTQStrTypeRight
};
#define PushStr(dblQuot, type) \
    [strings addObject:[NSDictionary dictionaryWithObjectsAndKeys: \
        [NSNumber numberWithBool:dblQuot], @"dblQuot", \
        [NSNumber numberWithInt:type], @"type", \
        [NSMutableData data], @"value", nil]];
#define PopStr() ({ id last = [Str() retain]; [strings removeLastObject]; [last autorelease]; })
#define StrData() [[strings lastObject] objectForKey:@"value"]
#define Str() [[[NSMutableString alloc] initWithData:StrData() encoding:NSUTF8StringEncoding] autorelease]
#define IsDblQuot() [[[strings lastObject] objectForKey:@"dblQuot"] boolValue]
#define IsRstr() ([[[strings lastObject] objectForKey:@"type"] intValue] == kTQStrTypeRight)
#define IsSimpleStr() ([[[strings lastObject] objectForKey:@"type"] intValue] == kTQStrTypeSimple)

typedef struct {
    int currentLine;
    BOOL atBeginningOfExpr;
    TQNodeRootBlock *root;
    NSError *syntaxError;
} TQParserState;

#define NSStr(lTrim, rTrim) (ts ? [[[NSMutableString alloc] initWithBytes:ts+(lTrim) length:te-ts-(lTrim)-(rTrim) encoding:NSUTF8StringEncoding] autorelease] : nil)

#define CopyCStr() ((unsigned char *)strndup((char *)ts, te-ts))

#define _EmitToken(tokenId, val) do { \
    int tokenId_ = tokenId; \
    id val_ = val; \
    /*NSLog(@"emitting %d = '%@' on line: %d", tokenId, val_, parserState.currentLine); */\
    Parse(parser, tokenId_, [TQToken withId:tokenId value:val_ line:parserState.currentLine], &parserState); \
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
    _EmitToken(tokenId, [NSNumber numberWithLongLong:numVal]); \
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
    else if(strncmp("else", (const char*)p-3, 4) == 0) \
        p -= 4; \
    for(unsigned char *cursor = ts; cursor != te; ++cursor) { \
        if(*cursor == '\n') \
            IncrementLine(); \
    } \
} while(0)

#define ExprBeg() parserState.atBeginningOfExpr = YES

@interface TQToken : NSObject
@property(readwrite, assign) NSUInteger id, lineNumber;
@property(readwrite, strong) id value;
+ (TQToken *)withId:(int)id value:(id)value line:(int)line;
@end
@implementation TQToken
+ (TQToken *)withId:(int)id value:(id)value line:(int)line
{
    TQToken *ret = [self new];
    ret.id = id;
    ret.value = value;
    ret.lineNumber = line;
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

    lGuillemet  = 0xC2 0xAB; # «
    rGuillemet  = 0xC2 0xBB; # »
    specialChar = 0xC2 | '"' | "'" | '.' | ',' | ';' | ':' | '|' | '#' | '@' | '~' | '`' | '{' | '}' | '[' | ']' | '(' | ')' | '+' | '-' | '*' | '/' | '%' | '=' | '<' | '>' | '^' | '\\' | '\r' | '\n' | space;

    char        = (any - specialChar) | (0xC2 ^(0xAB|0xBB));
    constant    = '_'* uupper char*;
    identifier  = (char -- (uupper|udigit)) char*;
    comment     = '\\' [^\n]*;
    nl          = ((space|comment)* '\n' space*);
    whitespace  = (nl|space|comment);
    whitespaceNoNl  = (" "|"\t"|comment);
    term        = whitespace* (nl|"}"|"else");

    constStr    = "#" (char | [:@#~+\-*/%=<>^])+;
    selector    = char* ":";

    regexCont   = (ualnum | ascii) - '/' - '\\';

string := |*
    '\n'                             => { [StrData() appendBytes:"\n" length:1]; IncrementLine();        };
    '\\n'                            => { [StrData() appendBytes:"\n" length:1];                         };
    '\\t'                            => { [StrData() appendBytes:"\t" length:1];                         };
    '\\r'                            => { [StrData() appendBytes:"\r" length:1];                         };
    '\\"'                            => { [StrData() appendBytes:"\"" length:1];                         };
    "\\'"                            => { [StrData() appendBytes:"'"  length:1];                         };
    "\\\\"                           => { [StrData() appendBytes:"\\" length:1];                         };
    "\\" lGuillemet                  => { [StrData() appendBytes:"«"  length:2];                         };
    '\\x' %{ temp1 = p; } [0-9a-zA-Z]* => {
        long long code = strtoll((char*)temp1, NULL, 16);
        NSString *strVal = [NSString stringWithFormat:@"%c", (int)code];
        [StrData() appendData:[strVal dataUsingEncoding:NSUTF8StringEncoding]];
    };
    "\\" any                         => { TQAssert(NO, @"Invalid escape %@", NSStr(0,0));                };

    lGuillemet                       => { 
        TQAssert(!IsSimpleStr(), @"Interpolation is not allowed in constant strings");
        _EmitToken(IsRstr() ? MSTR : LSTR, Str());
        fret;
    };
    '"' term => {
        if(IsDblQuot()) {
            int tokId = IsSimpleStr() ? CONSTSTRNL
                                      : (IsRstr() ? RSTRNL : STRNL);
            _EmitToken(tokId, PopStr());
            BacktrackTerm();
            fret;
        } else
            [StrData() appendBytes:@"\"" length:1];
    };
    '"' => {
        if(IsDblQuot()) {
            int tokId = IsSimpleStr() ? CONSTSTR
                                      : (IsRstr() ? RSTR : STR);
            _EmitToken(tokId, PopStr());
            fret;
        } else
            [StrData() appendBytes:@"\"" length:1];
    };
    "'" term => {
        if(!IsDblQuot()) {
            int tokId = IsSimpleStr() ? CONSTSTRNL
                                      : (IsRstr() ? RSTRNL : STRNL);
            _EmitToken(tokId, PopStr());
            BacktrackTerm();
            fret;
        } else
            [StrData() appendBytes:@"'" length:1];
    };
    "'" => {
        if(!IsDblQuot()) {
            int tokId = IsSimpleStr() ? CONSTSTR
                                      : (IsRstr() ? RSTR : STR);
            _EmitToken(tokId, PopStr());
            fret;
        } else
            [StrData() appendBytes:@"'" length:1];
    };

    any => { [StrData() appendBytes:ts length:1];                                                         };
*|;

regex := |*
    '\n'                             => { [StrData() appendBytes:"\n"  length:1]; IncrementLine();        };
    "\\/"                            => { [StrData() appendBytes:"\\/" length:1];                         };
    "\\"                             => { [StrData() appendBytes:"\\"  length:1];                         };
    regexCont                        => { [StrData() appendBytes:ts    length:1];                         };
    "/" [im]* term                   => { [StrData() appendBytes:"/"   length:1];
                                          _EmitToken(REGEXNL, PopStr());
                                          BacktrackTerm(); fret;                                          };
    "/" [im]*                        => { [StrData() appendBytes:"/" length:1];
                                          _EmitToken(REGEX, PopStr()); fret;                              };
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
        } else {
            PushStr(false, kTQStrTypeLeftOrMiddle);
            [StrData() appendBytes:"/" length:1];
            fcall regex;
        }
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
    "@"                              => { EmitToken(ATMARK);                                              };
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
    "do"      term?                  => { EmitToken(DO);        ExprBeg(); BacktrackTerm();               };
    "else"    term                   => { EmitToken(ELSE);      ExprBeg(); BacktrackTerm();               };
    "else"                           => { EmitToken(ELSE);      ExprBeg();                                };
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
    constant   %{temp1 = p;} term    => { EmitStringToken(CONSTNL, 0, te-temp1); ExprBeg(); BacktrackTerm(); };
    constant                         => { EmitStringToken(CONST,   0, 0);                                 };

    identifier %{temp1 = p;} term    => { EmitStringToken(IDENTNL, 0, te-temp1); ExprBeg(); BacktrackTerm(); };
    identifier                       => { EmitStringToken(IDENT,   0, 0);                                 };

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

    "#" '"'                          => { PushStr(YES, kTQStrTypeSimple); fcall string;                   };
    "#" "'"                          => { PushStr(NO, kTQStrTypeSimple);  fcall string;                   };
    constStr %{temp1 = p;} term      => { EmitConstStringToken(CONSTSTRNL, 0, te-temp1); ExprBeg(); BacktrackTerm(); };
    constStr                         => { EmitConstStringToken(CONSTSTR, 0, 0);                           };

    '"'                              => { PushStr(YES, kTQStrTypeLeftOrMiddle); fcall string;             };
    "'"                              => { PushStr(NO, kTQStrTypeLeftOrMiddle);  fcall string;             };
    rGuillemet                       => {
        BOOL dbl = IsDblQuot();
        PopStr();
        PushStr(dbl, kTQStrTypeRight);
        fcall string;
    };

    "."                              => { EmitToken(PERIOD);                                              };
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
    NSMutableArray *strings = [NSMutableArray array];

    unsigned char *temp1, *temp2;

    // Parser setup
    void *parser = ParseAlloc(malloc);
    TQParserState parserState = {
        1, YES, [TQNodeRootBlock new], nil
    };

    @try {
        %% write init;
        %% write exec;

        if(p != pe)
            fprintf(stderr, "invalid character '%c'\n", p[0]);

        _EmitToken(0, @"EOF");
        return [parserState.root autorelease];
    } @catch(NSException *e) {
        if(aoErr)
            *aoErr = parserState.syntaxError;
        return nil;
    } @finally {
        ParseFree(parser, free);
    }
    return nil;
}
