#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include "parse.h"

typedef struct {
    int id;
    int line;
    int len;
    const unsigned char *stringValue;
    double doubleValue;
} Token;

// You need to free
#define NSStr(lTrim, rTrim) [[[NSMutableString alloc] initWithBytes:ts+(lTrim) length:te-ts-(lTrim)-(rTrim) encoding:NSUTF8StringEncoding] autorelease]

#define CopyCStr() ((unsigned char *)strndup((char *)ts, te-ts))

#define _EmitToken(tokenId, val) Parse(parser, tokenId, val, &parserState)

#define EmitToken(tokenId) _EmitToken(tokenId, nil)

#define EmitStringToken(tokenId, lTrim, rTrim) _EmitToken(tokenId, NSStr(lTrim, rTrim))

#define EmitIntToken(base, prefixLen) do { \
    unsigned char *str = CopyCStr(); \
    long long numVal = strtoll((char *)str + (prefixLen), NULL, (base)); \
    _EmitToken(NUMBER, [NSNumber numberWithLongLong:numVal]); \
    free(str); \
} while(0)

#define EmitFloatToken() do { \
    unsigned char *str = CopyCStr(); \
    _EmitToken(NUMBER, [NSNumber numberWithDouble:atof((char *)str)]); \
    free(str); \
} while(0)

%%{
    machine Tranquil;
    alphtype unsigned char;
    include WChar "utf8.rl";

    int         = udigit+;
    float       = (udigit+)? '.' udigit+;
    hex         = "0x"i xdigit+;
    bin         = "0b"i [0-1]+;
    oct         = "0o"i [0-7]+;

    newline     = ('\n' space?)+;
    char        = ualpha | '?' | '!';
    constant    = uupper char*;
    identifier  = ulower char*;
    comment     = '\\' [^\n]*;

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
    "{"  { EmitToken(LBRACE); };
    "}"  { EmitToken(RBRACE); };
    "["  { EmitToken(LBRACKET); };
    "]"  { EmitToken(RBRACKET); };
    "("  { EmitToken(LPAREN); };
    ")"  { EmitToken(RPAREN); };
    ","  { EmitToken(COMMA);  };
    "`"  {  };
    ";"  {  };
    "\"" {  };
    "'"  {  };
    "="  { EmitToken(ASSIGN); };
    "+"  { EmitToken(PLUS); };
    "-"  { EmitToken(MINUS); };
    "--" { EmitToken(DECR); };
    "++" { EmitToken(INCR); };
    "*"  { EmitToken(ASTERISK); };
    "/"  { EmitToken(FSLASH); };
    "~"  { printf("~\n");  };
    "#"  { printf("#\n");  };
    "|"  { printf("|\n");  };
    "&"  { printf("&\n");  };
    "^"  { printf("^\n");  };
    "="  { EmitToken(ASSIGN); };
    "==" { printf("==\n"); };
    "~=" { printf("~=\n"); };
    "<"  { EmitToken(LESSER); };
    ">"  { EmitToken(GREATER); };
    "<=" { EmitToken(LEQUAL); };
    ">=" { EmitToken(GEQUAL); };
    "<<" { printf("<<\n"); };
    ">>" { printf(">>\n"); };
    "=>" { EmitToken(DICTSEP); };
    newline => { EmitToken(NL); };

# Keywords
#    "if"      { EmitStringToken(IF, 0, 0); };
#    "else"    { EmitStringToken(ELSE, 0, 0); };
    "and"|"||" { EmitToken(AND); };
    "or"|"&&"  { EmitToken(OR); };
#    "while"   { EmitStringToken(WHILE, 0, 0); };
#    "until"   { EmitStringToken(UNTIL, 0, 0); };
#    "import"  { EmitStringToken(IMPORT, 0, 0); };
#    "async"   { EmitStringToken(ASYNC, 0, 0); };
#    "break"   { EmitStringToken(BREAK, 0, 0); };
#    "skip"    { EmitStringToken(SKIP, 0, 0); };
    "self"    { EmitStringToken(SELF, 0, 0); };
    "super"   { EmitStringToken(SUPER, 0, 0); };
    "..."     { EmitStringToken(VAARG, 0, 0); };
    "nil"     { EmitStringToken(NIL, 0, 0); };
    "valid"   { EmitStringToken(VALID, 0, 0); };
    "yes"     { EmitStringToken(YES, 0, 0); };
    "no"      { EmitStringToken(NO, 0, 0); };
    "nothing" { EmitStringToken(NOTHING, 0, 0); };

    identifier => { EmitStringToken(IDENT, 0, 0); };
    constant   => { EmitStringToken(CONST, 0, 0); };
    selector   => { EmitStringToken(SELPART, 0, 1); };

    int        => { EmitIntToken(10, 0); };
    float      => { EmitFloatToken(); };
    bin        => { EmitIntToken(2, 2); };
    oct        => { EmitIntToken(8, 2); };
    hex        => { EmitIntToken(16, 2); };
    lStr       => { EmitStringToken(LSTR, 1,2); };
    mStr       => { EmitStringToken(MSTR, 2,2); };
    rStr       => { EmitStringToken(RSTR, 2,1); };
    string     => { EmitStringToken(STR, 1,1); };

    comment;
    space;
*|;

}%%

%% write data nofinal;

#import <Tranquil/CodeGen/TQNodeBlock.h>

typedef struct {
    NSUInteger currentLine;
    TQNodeRootBlock *root;
} TQParserState;

#include "parse.mm"

TQNode *TQParseString(NSString *str)
{
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
