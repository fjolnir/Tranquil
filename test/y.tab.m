#ifndef lint
static const char yysccsid[] = "@(#)yaccpar	1.9 (Berkeley) 02/21/93";
#endif

#define YYBYACC 1
#define YYMAJOR 1
#define YYMINOR 9
#define YYPATCH 20120115

#define YYEMPTY        (-1)
#define yyclearin      (yychar = YYEMPTY)
#define yyerrok        (yyerrflag = 0)
#define YYRECOVERING() (yyerrflag != 0)

#define YYPREFIX "yy"

#define YYPURE 0

#line 2 "parse.y"
	#include <Foundation/Foundation.h>
	#include "TQSyntaxTree.h"
	#include <stdio.h>
	#include <stdlib.h>
	extern int yylineno;
	extern char* yytext;
	int yylex(void);
#line 11 "parse.y"
#ifdef YYSTYPE
#undef  YYSTYPE_IS_DECLARED
#define YYSTYPE_IS_DECLARED 1
#endif
#ifndef YYSTYPE_IS_DECLARED
#define YYSTYPE_IS_DECLARED 1
typedef union {
	TQSyntaxNode *node;
	TQSyntaxNodeNumber *number;
	TQSyntaxNodeString *string;
	TQSyntaxNodeVariable *variable;
	TQSyntaxNodeArgument *arg;
	TQSyntaxNodeBlock *block;
	TQSyntaxNodeCall *call;
	TQSyntaxNodeClass *class;
	TQSyntaxNodeMethod *method;
	TQSyntaxNodeMessage *message;
	TQSyntaxNodeMemberAccess *memberAccess;
	TQSyntaxNodeBinaryOperator *binOp;
} YYSTYPE;
#endif /* !YYSTYPE_IS_DECLARED */
#line 49 "y.tab.m"

/* compatibility with bison */
#ifdef YYPARSE_PARAM
/* compatibility with FreeBSD */
# ifdef YYPARSE_PARAM_TYPE
#  define YYPARSE_DECL() yyparse(YYPARSE_PARAM_TYPE YYPARSE_PARAM)
# else
#  define YYPARSE_DECL() yyparse(void *YYPARSE_PARAM)
# endif
#else
# define YYPARSE_DECL() yyparse(void)
#endif

/* Parameters sent to lex. */
#ifdef YYLEX_PARAM
# define YYLEX_DECL() yylex(void *YYLEX_PARAM)
# define YYLEX yylex(YYLEX_PARAM)
#else
# define YYLEX_DECL() yylex(void)
# define YYLEX yylex()
#endif

/* Parameters sent to yyerror. */
#ifndef YYERROR_DECL
#define YYERROR_DECL() yyerror(const char *s)
#endif
#ifndef YYERROR_CALL
#define YYERROR_CALL(msg) yyerror(msg)
#endif

extern int YYPARSE_DECL();

#define tCLASS 257
#define tEND 258
#define tNUMBER 259
#define tSTRING 260
#define tIDENTIFIER 261
#define YYERRCODE 256
static const short yylhs[] = {                           -1,
    2,    4,    4,    1,    0,    0,   14,   14,    3,    3,
    3,    3,    3,    3,    3,   19,   19,   19,   19,   12,
   12,   20,   20,   20,   21,    8,   16,   16,   22,   22,
   22,   23,   23,   23,   23,   23,    6,   24,   24,   25,
    9,    9,   10,   10,   26,   27,   28,   28,   29,    7,
   11,   11,   15,   30,   30,   30,   13,   17,   17,   18,
    5,    5,
};
static const short yylen[] = {                            2,
    3,    1,    1,    1,    1,    2,    1,    1,    1,    1,
    1,    2,    1,    1,    3,    1,    1,    1,    3,    6,
    3,    3,    4,    5,    1,    1,    2,    3,    3,    4,
    5,    1,    3,    1,    1,    3,    6,    3,    1,    1,
    1,    3,    1,    1,    2,    2,    3,    2,    3,    3,
    1,    3,    2,    1,    1,    3,    0,    0,    2,    2,
    1,    1,
};
static const short yydefred[] = {                        57,
    0,    5,    0,   61,   62,    4,    0,    0,    3,   58,
    8,    0,    0,    7,    2,    0,    0,    6,    9,   11,
    0,    0,   40,   57,    0,    0,    0,    0,    0,    0,
    0,    0,   27,    0,    0,    0,   18,   16,   53,   58,
   41,    0,    0,    0,    0,   21,    0,   59,    0,    1,
   50,    0,    0,   35,   32,   58,   26,    0,   28,    0,
    0,    0,   38,   60,   25,   58,   57,    0,    0,    0,
    0,    0,   58,    0,   19,   52,   58,    0,    0,   42,
   43,   44,    0,    0,   58,    0,   36,   33,    0,   58,
    0,    0,   45,   46,   20,    0,   58,    0,   57,    0,
   48,    0,    0,   47,   49,
};
static const short yydgoto[] = {                          1,
    9,   10,   11,   12,   13,   14,   15,   69,   40,   80,
   16,   17,    2,   18,   19,   20,   44,   76,   21,   49,
   66,   34,   56,   24,   25,   81,   82,   93,  101,   22,
};
static const short yysindex[] = {                         0,
  -12,    0, -231,    0,    0,    0,  -17,    0,    0,    0,
    0,  -26,    0,    0,    0,    9,    0,    0,    0,    0,
   77,   44,    0,    0,   -2,    4,  -34,   14,   50,  -17,
 -197,   47,    0,  -44,  -17,    0,    0,    0,    0,    0,
    0, -180,    0,   36,    0,    0, -171,    0,  -42,    0,
    0,  -17,   32,    0,    0,    0,    0,   47,    0,   41,
   53,   40,    0,    0,    0,    0,    0, -171,   52,   60,
   47,   50,    0,   47,    0,    0,    0, -156, -156,    0,
    0,    0,   50,  -28,    0, -171,    0,    0,   50,    0,
   50,  -19,    0,    0,    0,   50,    0,   50,    0,  -58,
    0,   50,  -23,    0,    0,
};
static const short yyrindex[] = {                         0,
    0,    0,    0,    0,    0,    0,    0,   -7,    0,    0,
    0,    1,    8,    0,    0,    0,   15,    0,    0,    0,
    0,    0,    0,    0,   43,   98,    0,    0,   27,    0,
    0,    0,    0,    0,    0,   84,    0,    0,    0,    0,
    0,    0,  -20,    0,   22,    0,    0,    0,    0,    0,
    0,    0,   -6,    0,    0,    0,    0,    0,    0,    0,
   98,    0,    0,    0,    0,    0,    0,    0,    0,   98,
    0,  -39,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,  -53,    0,    0,    0,    0,    0,  -37,    0,
   34,    0,    0,    0,    0,  -48,    0,  -15,    0,    0,
    0,  -45,    0,    0,    0,
};
static const short yygindex[] = {                        29,
    0,    0,   85,   90,   95,    0,    0,   35,    0,    0,
    0,  119,   97,    0,    0,  103,   99,  106,    0,   37,
   12,    0,  100,    0,    0,    0,    0,   55,   46,    0,
};
#define YYTABLESIZE 308
static const short yytable[] = {                         68,
   13,   59,   58,   34,   22,    7,   29,   14,   30,   23,
   13,    7,   24,   58,   10,   68,    7,   14,   29,   56,
   30,   15,    7,   48,   10,   19,   12,    7,   51,   23,
   31,   15,   57,   37,   30,   51,   27,   19,   47,   34,
   13,   13,   31,   31,   43,   48,   17,   14,   14,   48,
   58,   34,   39,   18,   10,   10,   52,   42,   17,   48,
   16,   15,   15,   51,   99,   18,   12,   12,   60,   22,
   22,   47,   16,   37,   23,   23,   64,   24,   24,   85,
   63,   67,   78,   35,   79,   39,   52,   39,    8,   65,
   46,   26,   71,   75,    8,   84,   95,   97,   74,    8,
   87,  105,   56,   99,   57,    8,   28,   58,   29,   86,
    8,   36,   92,   92,   50,   57,   37,   57,   51,   61,
   41,   53,   33,   13,   39,   13,   54,  103,  100,   17,
   14,   45,   14,   94,   32,    0,   70,   10,   62,   10,
   38,   17,    0,    0,   15,  104,   15,   53,    0,   12,
   55,   12,   54,    0,   72,    0,   37,   73,   37,    0,
   53,    0,    0,   53,   83,   54,    8,    0,   54,    8,
   88,   89,    0,   90,    0,   91,   55,    0,    0,    0,
    0,    0,    0,   96,    0,    0,    0,    0,   98,   55,
    0,    0,   55,    0,    0,  102,    0,    0,    0,    0,
    0,    0,   57,    0,    0,    0,    0,   22,    0,    0,
    0,    0,   23,    0,    0,   24,   57,    0,   57,    0,
    0,   29,    3,   30,    4,    5,    6,    0,    3,    0,
    4,    5,    6,    3,    0,    4,    5,    6,   56,   56,
   56,    4,    5,    6,    3,   31,    4,    5,    6,   57,
    0,   57,   57,   57,   34,    0,    0,   13,    0,   13,
   13,   13,    0,    0,   14,    0,   14,   14,   14,    0,
    0,   10,    0,   10,   10,   10,    0,    0,   15,    0,
   15,   15,   15,   12,    0,   12,   12,   12,    0,    0,
   37,    0,   37,   37,   37,    0,    0,   77,    0,    0,
   39,    0,    4,    5,    6,    4,    5,    6,
};
static const short yycheck[] = {                         58,
    0,   46,   10,   10,   58,   40,   46,    0,   46,   58,
   10,   40,   58,   58,    0,   58,   40,   10,   58,   40,
   58,    0,   40,   10,   10,   46,    0,   40,   35,  261,
   46,   10,   40,    0,   61,   35,    8,   58,   58,   46,
   40,   41,   58,   35,   41,   10,   46,   40,   41,   10,
   58,   58,   10,   46,   40,   41,   35,   60,   58,   10,
   46,   40,   41,  261,  123,   58,   40,   41,   34,  123,
  124,   58,   58,   40,  123,  124,   41,  123,  124,   68,
  261,  124,   43,   40,   45,   43,   40,   45,  123,  261,
  125,    7,   61,   41,  123,   67,  125,   86,   58,  123,
   41,  125,  123,  123,  261,  123,    8,   10,   10,   58,
  123,   22,   78,   79,   30,  123,   22,  125,   35,   35,
   24,   32,   46,  123,   22,  125,   32,   99,   92,   46,
  123,   26,  125,   79,   58,   -1,   52,  123,   40,  125,
   22,   58,   -1,   -1,  123,  100,  125,   58,   -1,  123,
   32,  125,   58,   -1,   56,   -1,  123,   58,  125,   -1,
   71,   -1,   -1,   74,   66,   71,  123,   -1,   74,  123,
   71,   73,   -1,   74,   -1,   77,   58,   -1,   -1,   -1,
   -1,   -1,   -1,   85,   -1,   -1,   -1,   -1,   90,   71,
   -1,   -1,   74,   -1,   -1,   97,   -1,   -1,   -1,   -1,
   -1,   -1,  261,   -1,   -1,   -1,   -1,  261,   -1,   -1,
   -1,   -1,  261,   -1,   -1,  261,  261,   -1,  261,   -1,
   -1,  261,  257,  261,  259,  260,  261,   -1,  257,   -1,
  259,  260,  261,  257,   -1,  259,  260,  261,  259,  260,
  261,  259,  260,  261,  257,  261,  259,  260,  261,  257,
   -1,  259,  260,  261,  261,   -1,   -1,  257,   -1,  259,
  260,  261,   -1,   -1,  257,   -1,  259,  260,  261,   -1,
   -1,  257,   -1,  259,  260,  261,   -1,   -1,  257,   -1,
  259,  260,  261,  257,   -1,  259,  260,  261,   -1,   -1,
  257,   -1,  259,  260,  261,   -1,   -1,  258,   -1,   -1,
  258,   -1,  259,  260,  261,  259,  260,  261,
};
#define YYFINAL 1
#ifndef YYDEBUG
#define YYDEBUG 1
#endif
#define YYMAXTOKEN 261
#if YYDEBUG
static const char *yyname[] = {

"end-of-file",0,0,0,0,0,0,0,0,0,"'\\n'",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,"'#'",0,0,0,0,"'('","')'",0,"'+'",0,"'-'","'.'",0,0,0,0,0,0,0,0,0,0,0,
"':'",0,"'<'","'='",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,"'{'","'|'","'}'",
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,"tCLASS","tEND","tNUMBER","tSTRING","tIDENTIFIER",
};
static const char *yyrule[] = {
"$accept : statements",
"assignment : lhs '=' expression",
"lhs : member_access",
"lhs : variable",
"variable : tIDENTIFIER",
"statements : empty",
"statements : statements statement",
"statement : class",
"statement : expression",
"expression : message",
"expression : block",
"expression : call",
"expression : assignment opt_nl",
"expression : lhs",
"expression : literal",
"expression : '(' expression rparen",
"callee : block",
"callee : lhs",
"callee : literal",
"callee : '(' expression ')'",
"block : '{' opt_nl block_args '|' statements '}'",
"block : '{' statements '}'",
"block_args : ':' block_arg opt_nl",
"block_args : block_args ':' block_arg opt_nl",
"block_args : block_args block_arg_identifier ':' block_arg opt_nl",
"block_arg : tIDENTIFIER",
"block_arg_identifier : tIDENTIFIER",
"call : callee '.'",
"call : callee call_args '.'",
"call_args : ':' call_arg opt_nl",
"call_args : call_args ':' call_arg opt_nl",
"call_args : call_args block_arg_identifier ':' call_arg opt_nl",
"call_arg : block",
"call_arg : lhs '=' call_arg",
"call_arg : lhs",
"call_arg : literal",
"call_arg : '(' expression ')'",
"class : tCLASS class_def methods opt_nl tEND opt_nl",
"class_def : class_name '<' tIDENTIFIER",
"class_def : class_name",
"class_name : tIDENTIFIER",
"methods : empty",
"methods : methods opt_nl method",
"method : class_method",
"method : instance_method",
"class_method : '+' method_def",
"instance_method : '-' method_def",
"method_def : block_arg_identifier block_args method_body",
"method_def : block_arg_identifier method_body",
"method_body : '{' statements '}'",
"member_access : accessable '#' tIDENTIFIER",
"accessable : lhs",
"accessable : '(' expression rparen",
"message : message_receiver call",
"message_receiver : lhs",
"message_receiver : literal",
"message_receiver : '(' expression ')'",
"empty :",
"opt_nl :",
"opt_nl : opt_nl '\\n'",
"rparen : opt_nl ')'",
"literal : tNUMBER",
"literal : tSTRING",

};
#endif

int      yydebug;
int      yynerrs;

int      yyerrflag;
int      yychar;
YYSTYPE  yyval;
YYSTYPE  yylval;

/* define the initial stack-sizes */
#ifdef YYSTACKSIZE
#undef YYMAXDEPTH
#define YYMAXDEPTH  YYSTACKSIZE
#else
#ifdef YYMAXDEPTH
#define YYSTACKSIZE YYMAXDEPTH
#else
#define YYSTACKSIZE 500
#define YYMAXDEPTH  500
#endif
#endif

#define YYINITSTACKSIZE 500

typedef struct {
    unsigned stacksize;
    short    *s_base;
    short    *s_mark;
    short    *s_last;
    YYSTYPE  *l_base;
    YYSTYPE  *l_mark;
} YYSTACKDATA;
/* variables for the parser stack */
static YYSTACKDATA yystack;
#line 178 "parse.y"

int yyerror(char *str)
{
	fprintf(stderr, "%d: error: '%s' at '%s'\n", yylineno, str, yytext);

	exit(3);
	return 0;
}

int yywrap(void) {
	return 1;
}

int main()
{
	yydebug = 5;
	yyparse();
	return 0;
}
#line 360 "y.tab.m"

#if YYDEBUG
#include <stdio.h>		/* needed for printf */
#endif

#include <stdlib.h>	/* needed for malloc, etc */
#include <string.h>	/* needed for memset */

/* allocate initial stack or double stack size, up to YYMAXDEPTH */
static int yygrowstack(YYSTACKDATA *data)
{
    int i;
    unsigned newsize;
    short *newss;
    YYSTYPE *newvs;

    if ((newsize = data->stacksize) == 0)
        newsize = YYINITSTACKSIZE;
    else if (newsize >= YYMAXDEPTH)
        return -1;
    else if ((newsize *= 2) > YYMAXDEPTH)
        newsize = YYMAXDEPTH;

    i = data->s_mark - data->s_base;
    newss = (short *)realloc(data->s_base, newsize * sizeof(*newss));
    if (newss == 0)
        return -1;

    data->s_base = newss;
    data->s_mark = newss + i;

    newvs = (YYSTYPE *)realloc(data->l_base, newsize * sizeof(*newvs));
    if (newvs == 0)
        return -1;

    data->l_base = newvs;
    data->l_mark = newvs + i;

    data->stacksize = newsize;
    data->s_last = data->s_base + newsize - 1;
    return 0;
}

#if YYPURE || defined(YY_NO_LEAKS)
static void yyfreestack(YYSTACKDATA *data)
{
    free(data->s_base);
    free(data->l_base);
    memset(data, 0, sizeof(*data));
}
#else
#define yyfreestack(data) /* nothing */
#endif

#define YYABORT  goto yyabort
#define YYREJECT goto yyabort
#define YYACCEPT goto yyaccept
#define YYERROR  goto yyerrlab

int
YYPARSE_DECL()
{
    int yym, yyn, yystate;
#if YYDEBUG
    const char *yys;

    if ((yys = getenv("YYDEBUG")) != 0)
    {
        yyn = *yys;
        if (yyn >= '0' && yyn <= '9')
            yydebug = yyn - '0';
    }
#endif

    yynerrs = 0;
    yyerrflag = 0;
    yychar = YYEMPTY;
    yystate = 0;

#if YYPURE
    memset(&yystack, 0, sizeof(yystack));
#endif

    if (yystack.s_base == NULL && yygrowstack(&yystack)) goto yyoverflow;
    yystack.s_mark = yystack.s_base;
    yystack.l_mark = yystack.l_base;
    yystate = 0;
    *yystack.s_mark = 0;

yyloop:
    if ((yyn = yydefred[yystate]) != 0) goto yyreduce;
    if (yychar < 0)
    {
        if ((yychar = YYLEX) < 0) yychar = 0;
#if YYDEBUG
        if (yydebug)
        {
            yys = 0;
            if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
            if (!yys) yys = "illegal-symbol";
            printf("%sdebug: state %d, reading %d (%s)\n",
                    YYPREFIX, yystate, yychar, yys);
        }
#endif
    }
    if ((yyn = yysindex[yystate]) && (yyn += yychar) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yychar)
    {
#if YYDEBUG
        if (yydebug)
            printf("%sdebug: state %d, shifting to state %d\n",
                    YYPREFIX, yystate, yytable[yyn]);
#endif
        if (yystack.s_mark >= yystack.s_last && yygrowstack(&yystack))
        {
            goto yyoverflow;
        }
        yystate = yytable[yyn];
        *++yystack.s_mark = yytable[yyn];
        *++yystack.l_mark = yylval;
        yychar = YYEMPTY;
        if (yyerrflag > 0)  --yyerrflag;
        goto yyloop;
    }
    if ((yyn = yyrindex[yystate]) && (yyn += yychar) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yychar)
    {
        yyn = yytable[yyn];
        goto yyreduce;
    }
    if (yyerrflag) goto yyinrecovery;

    yyerror("syntax error");

    goto yyerrlab;

yyerrlab:
    ++yynerrs;

yyinrecovery:
    if (yyerrflag < 3)
    {
        yyerrflag = 3;
        for (;;)
        {
            if ((yyn = yysindex[*yystack.s_mark]) && (yyn += YYERRCODE) >= 0 &&
                    yyn <= YYTABLESIZE && yycheck[yyn] == YYERRCODE)
            {
#if YYDEBUG
                if (yydebug)
                    printf("%sdebug: state %d, error recovery shifting\
 to state %d\n", YYPREFIX, *yystack.s_mark, yytable[yyn]);
#endif
                if (yystack.s_mark >= yystack.s_last && yygrowstack(&yystack))
                {
                    goto yyoverflow;
                }
                yystate = yytable[yyn];
                *++yystack.s_mark = yytable[yyn];
                *++yystack.l_mark = yylval;
                goto yyloop;
            }
            else
            {
#if YYDEBUG
                if (yydebug)
                    printf("%sdebug: error recovery discarding state %d\n",
                            YYPREFIX, *yystack.s_mark);
#endif
                if (yystack.s_mark <= yystack.s_base) goto yyabort;
                --yystack.s_mark;
                --yystack.l_mark;
            }
        }
    }
    else
    {
        if (yychar == 0) goto yyabort;
#if YYDEBUG
        if (yydebug)
        {
            yys = 0;
            if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
            if (!yys) yys = "illegal-symbol";
            printf("%sdebug: state %d, error recovery discards token %d (%s)\n",
                    YYPREFIX, yystate, yychar, yys);
        }
#endif
        yychar = YYEMPTY;
        goto yyloop;
    }

yyreduce:
#if YYDEBUG
    if (yydebug)
        printf("%sdebug: state %d, reducing by rule %d (%s)\n",
                YYPREFIX, yystate, yyn, yyrule[yyn]);
#endif
    yym = yylen[yyn];
    if (yym)
        yyval = yystack.l_mark[1-yym];
    else
        memset(&yyval, 0, sizeof yyval);
    switch (yyn)
    {
case 1:
#line 38 "parse.y"
	{ }
break;
case 4:
#line 47 "parse.y"
	{ }
break;
case 21:
#line 81 "parse.y"
	{ yyval.block = [[TQSyntaxNodeBlock alloc] init]; }
break;
case 25:
#line 89 "parse.y"
	{  }
break;
case 26:
#line 92 "parse.y"
	{  }
break;
case 50:
#line 142 "parse.y"
	{  }
break;
#line 590 "y.tab.m"
    }
    yystack.s_mark -= yym;
    yystate = *yystack.s_mark;
    yystack.l_mark -= yym;
    yym = yylhs[yyn];
    if (yystate == 0 && yym == 0)
    {
#if YYDEBUG
        if (yydebug)
            printf("%sdebug: after reduction, shifting from state 0 to\
 state %d\n", YYPREFIX, YYFINAL);
#endif
        yystate = YYFINAL;
        *++yystack.s_mark = YYFINAL;
        *++yystack.l_mark = yyval;
        if (yychar < 0)
        {
            if ((yychar = YYLEX) < 0) yychar = 0;
#if YYDEBUG
            if (yydebug)
            {
                yys = 0;
                if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
                if (!yys) yys = "illegal-symbol";
                printf("%sdebug: state %d, reading %d (%s)\n",
                        YYPREFIX, YYFINAL, yychar, yys);
            }
#endif
        }
        if (yychar == 0) goto yyaccept;
        goto yyloop;
    }
    if ((yyn = yygindex[yym]) && (yyn += yystate) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yystate)
        yystate = yytable[yyn];
    else
        yystate = yydgoto[yym];
#if YYDEBUG
    if (yydebug)
        printf("%sdebug: after reduction, shifting from state %d \
to state %d\n", YYPREFIX, *yystack.s_mark, yystate);
#endif
    if (yystack.s_mark >= yystack.s_last && yygrowstack(&yystack))
    {
        goto yyoverflow;
    }
    *++yystack.s_mark = (short) yystate;
    *++yystack.l_mark = yyval;
    goto yyloop;

yyoverflow:
    yyerror("yacc stack overflow");

yyabort:
    yyfreestack(&yystack);
    return (1);

yyaccept:
    yyfreestack(&yystack);
    return (0);
}
