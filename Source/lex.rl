#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include "parse.h"
#import <Tranquil/CodeGen/TQNodeBlock.h>

typedef struct {
    int currentLine;
    TQNodeRootBlock *root;
    int lastTokenId;
} TQParserState;

// You need to free
#define NSStr(lTrim, rTrim) [[[NSMutableString alloc] initWithBytes:ts+(lTrim) length:te-ts-(lTrim)-(rTrim) encoding:NSUTF8StringEncoding] autorelease]

#define CopyCStr() ((unsigned char *)strndup((char *)ts, te-ts))

#define _EmitToken(tokenId, val) do { \
    Parse(parser, tokenId, val, &parserState); \
    parserState.lastTokenId = tokenId; \
} while(0);

#define EmitToken(tokenId) _EmitToken(tokenId, nil)

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

#define LastToken() (parserState.lastTokenId)

%%{
    machine Tranquil;
    alphtype unsigned char;
    include WChar "utf8.rl";

    int         = udigit+;
    float       = (udigit+)? '.' udigit+;
    hex         = "0x"i xdigit+;
    bin         = "0b"i [0-1]+;
    oct         = "0o"i [0-7]+;

    char        = ualpha | '?' | '!';
    constant    = uupper char*;
    identifier  = ulower char*;
    comment     = '\\' [^\n]*;
    newline     = (comment? '\n' space?)+;

    lGuillmt    = 0xC2 0xAB; # «
    rGuillmt    = 0xC2 0xBB; # »
    strCont     = '\\' any | (ascii - '"') | ualpha;
    string      = '"' strCont* '"';
    lStr        = '"' strCont* lGuillmt;
    mStr        = rGuillmt strCont* lGuillmt;
    rStr        = rGuillmt strCont* '"';
    selector    = (constant | identifier)? ':';

main := |*
# Symbols
    "{"                => { EmitToken(LBRACE); };
    "}" newline        => { EmitToken(RBRACENL); };
    "}"                => { EmitToken(RBRACE); };
    "["                => { EmitToken(LBRACKET); };
    "]" newline        => { EmitToken(RBRACKETNL); };
    "]"                => { EmitToken(RBRACKET); };
    "("                => { EmitToken(LPAREN); };
    ")" newline        => { EmitToken(RPARENNL); };
    ")"                => { EmitToken(RPAREN); };
    ","                => { EmitToken(COMMA);  };
    "`" newline        => { EmitToken(BACKTICKNL); };
    "`"                => { EmitToken(BACKTICK); };
    ";"                => {  };
    "'"                => {  };
    "="                => { EmitToken(ASSIGN); };
    "+"                => { EmitToken(PLUS); };
    "-"                => { EmitToken(MINUS); };
    "--"               => { EmitToken(DECR); };
    "++"               => { EmitToken(INCR); };
    "*"                => { EmitToken(ASTERISK); };
    "/"                => { EmitToken(FSLASH); };
    "~"                => { printf("~\n");  };
    "#"                => { printf("#\n");  };
    "|"                => { printf("|\n");  };
    "&"                => { printf("&\n");  };
    "^"                => { printf("^\n");  };
    "="                => { EmitToken(ASSIGN); };
    "=="               => { printf("==\n"); };
    "~="               => { printf("~=\n"); };
    "<"                => { EmitToken(LESSER); };
    ">"                => { EmitToken(GREATER); };
    "<="               => { EmitToken(LEQUAL); };
    ">="               => { EmitToken(GEQUAL); };
    "<<"               => { printf("<<\n"); };
    ">>"               => { printf(">>\n"); };
    "=>"               => { EmitToken(DICTSEP); };

# Message selectors
    selector           => { EmitStringToken(SELPART, 0, 1); printf("SELPART %s\n", CopyCStr()); };

# Keywords
#    "if"               => { EmitStringToken(IF, 0, 0); };
#    "else"             => { EmitStringToken(ELSE, 0, 0); };
    "and"|"||"         => { EmitToken(AND); };
    "or"|"&&"          => { EmitToken(OR); };
#    "while"            => { EmitStringToken(WHILE, 0, 0); };
#    "until"            => { EmitStringToken(UNTIL, 0, 0); };
#    "import"           => { EmitStringToken(IMPORT, 0, 0); };
#    "async"            => { EmitStringToken(ASYNC, 0, 0); };
#    "break"            => { EmitStringToken(BREAK, 0, 0); };
#    "skip"             => { EmitStringToken(SKIP, 0, 0); };
    # These are identifier keywords used as expressions => need a *NL variant as well
    "self"    newline  => { EmitStringToken(SELFNL,    0, 0); };
    "super"   newline  => { EmitStringToken(SUPERNL,   0, 0); };
    "..."     newline  => { EmitStringToken(VAARGNL,   0, 0); };
    "nil"     newline  => { EmitStringToken(NILNL,     0, 0); };
    "valid"   newline  => { EmitStringToken(VALIDNL,   0, 0); };
    "yes"     newline  => { EmitStringToken(YESNL,     0, 0); };
    "no"      newline  => { EmitStringToken(NONL,      0, 0); };
    "nothing" newline  => { EmitStringToken(NOTHINGNL, 0, 0); };
    "self"             => { EmitStringToken(SELF,      0, 0); };
    "super"            => { EmitStringToken(SUPER,     0, 0); };
    "..."              => { EmitStringToken(VAARG,     0, 0); };
    "nil"              => { EmitStringToken(NIL,       0, 0); };
    "valid"            => { EmitStringToken(VALID,     0, 0); };
    "yes"              => { EmitStringToken(YES,       0, 0); };
    "no"               => { EmitStringToken(NO,        0, 0); };
    "nothing"          => { EmitStringToken(NOTHING,   0, 0); };


# Identifiers
    identifier newline => { EmitStringToken(IDENTNL, 0, 1); };
    identifier         => { EmitStringToken(IDENT,   0, 0); };

    constant newline   => { EmitStringToken(CONSTNL, 0, 1); };
    constant           => { EmitStringToken(CONST,   0, 0); };

# Literals
    int   newline      => { EmitIntToken(NUMBERNL, 10, 0); };
    float newline      => { EmitFloatToken(NUMBERNL);      };
    bin   newline      => { EmitIntToken(NUMBERNL, 2,  2); };
    oct   newline      => { EmitIntToken(NUMBERNL, 8,  2); };
    hex   newline      => { EmitIntToken(NUMBERNL, 16, 2); };

    int                => { EmitIntToken(NUMBER, 10, 0); };
    float              => { EmitFloatToken(NUMBER);      };
    bin                => { EmitIntToken(NUMBER, 2,  2); };
    oct                => { EmitIntToken(NUMBER, 8,  2); };
    hex                => { EmitIntToken(NUMBER, 16, 2); };

    lStr               => { EmitStringToken(LSTR,   1, 2); };
    mStr               => { EmitStringToken(MSTR,   2, 2); };
    rStr               => { EmitStringToken(RSTR,   2, 1); };
    rStr newline       => { EmitStringToken(RSTRNL, 2, 1); };
    string             => { EmitStringToken(STR,    1, 2); };
    string newline     => { EmitStringToken(STRNL,  1, 2); };

    newline;
    space;
*|;

}%%

%% write data nofinal;

#include "parse.mm"

TQNode *TQParseString(NSString *str)
{
    if(![str hasSuffix:@"\n"])
        str = [str stringByAppendingString:@"\n"];

    int cs, act;
    unsigned char *ts, *te = 0;

    // Lexer setup
    unsigned char *p = (unsigned char *)[str UTF8String];
    unsigned char *pe = p + strlen((char*)p);
    unsigned char *eof = pe;

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
    [parserState.root release];
    return 0;
}
