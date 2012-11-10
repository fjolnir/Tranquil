// Lemon grammar for tranquil

// (Let me apologize in advance for the *(No)Nl variants. This was the simplest way I could
//  think of to implement newline separated statements in a LALR(1) grammar; Including an NL
//  token would have been worse)

// TODO Make async* an expression returning a promise (Depends on actually implementing promises)

%token_type id
%extra_argument { TQParserState *state }

program ::= statements(SS). { [state->root setStatements:SS]; }

//
// Statements -------------------------------------------------------------------------------------------------------------------------
//

statements(SS) ::= statements(O) statement(S).          { SS = O; [SS addObject:S];                                                   }
statements(SS) ::= statement(S).                        { SS = [NSMutableArray arrayWithObject:S];                                    }

statement(S) ::= exprNl(E).                             { S = E;                                                                      }
statement(S) ::= exprNoNl(E) PERIOD.                    { S = E;                                                                      }
statement(S) ::= cond(C).                               { S = C;                                                                      }
statement(S) ::= loop(L).                               { S = L;                                                                      }
statement(S) ::= waitNl(W).                             { S = W;                                                                      }
statement(S) ::= waitNoNl(W) PERIOD.                    { S = W;                                                                      }
statement(S) ::= whenFinished(W).                       { S = W;                                                                      }
statement(S) ::= lock(L).                               { S = L;                                                                      }
statement(S) ::= collect(C).                            { S = C;                                                                      }
statement(S) ::= import(I).                             { S = I;                                                                      }
statement(S) ::= retNl(I).                              { S = I;                                                                      }
statement(S) ::= retNoNl(I) PERIOD.                     { S = I;                                                                      }

retNl(R)   ::= CARET exprNl(E).                         { R = [TQNodeReturn nodeWithValue:E];                                         }
retNl(R)   ::= CARET retNl(O).                          { R = O; [O setDepth:[O depth] + 1];                                          }
retNoNl(R) ::= CARET exprNoNl(E).                       { R = [TQNodeReturn nodeWithValue:E];                                         }
retNoNl(R) ::= CARET retNoNl(O).                        { R = O; [O setDepth:[O depth] + 1];                                          }


//
// Expressions ------------------------------------------------------------------------------------------------------------------------
//

expr(E) ::= exprNoNl(T).                                { E = T;                                                                      }
expr(E) ::= exprNl(T).                                  { E = T;                                                                      }

exprNoNl(E) ::= assignNoNl(O).                          { E = O;                                                                      }
exprNoNl(E) ::= noAsgnExprNoNl(O).                      { E = O;                                                                      }
exprNl(E)   ::= assignNl(O).                            { E = O;                                                                      }
exprNl(E)   ::= noAsgnExprNl(O).                        { E = O;                                                                      }

noAsgnExpr(E) ::= noAsgnExprNoNl(M).                    { E = M;                                                                      }
noAsgnExpr(E) ::= noAsgnExprNl(M).                      { E = M;                                                                      }

noAsgnExprNoNl(E) ::= kwdMsgNoNl(M).                    { E = M;                                                                      }
noAsgnExprNoNl(E) ::= opNoNl(O).                        { E = O;                                                                      }
noAsgnExprNoNl(E) ::= cascadeNoNl(C).                   { E = C;                                                                      }
noAsgnExprNoNl(E) ::= ternOpNoNl(O).                    { E = O;                                                                      }
noAsgnExprNoNl(E) ::= simpleExprNoNl(T).                { E = T;                                                                      }
noAsgnExprNoNl(E) ::= asyncNoNl(O).                     { E = O;                                                                      }
noAsgnExprNl(E) ::= kwdMsgNl(M).                        { E = M;                                                                      }
noAsgnExprNl(E) ::= opNl(O).                            { E = O;                                                                      }
noAsgnExprNl(E) ::= cascadeNl(C).                       { E = C;                                                                      }
noAsgnExprNl(E) ::= ternOpNl(O).                        { E = O;                                                                      }
noAsgnExprNl(E) ::= simpleExprNl(T).                    { E = T;                                                                      }
noAsgnExprNl(E) ::= asyncNl(O).                         { E = O;                                                                      }

parenExprNoNl(PE) ::= LPAREN expr(E) RPAREN.            { PE = E;                                                                     }
parenExprNl(PE)   ::= LPAREN expr(E) RPARENNL.          { PE = E;                                                                     }

simpleExprNoNl(E) ::= parenExprNoNl(PE).                { E = PE;                                                                     }
simpleExprNoNl(E) ::= literalNoNl(L).                   { E = L;                                                                      }
simpleExprNoNl(E) ::= constantNoNl(L).                  { E = L;                                                                      }
simpleExprNoNl(E) ::= unaryMsgNoNl(M).                  { E = M;                                                                      }
//simpleExprNoNl(E) ::= variableNoNl(L).                  { E = L;                                                                      }
//simpleExprNoNl(E) ::= subscriptNoNl(L).                 { E = L;                                                                      }
//simpleExprNoNl(E) ::= propertyNoNl(L).                  { E = L;                                                                      }
simpleExprNoNl(E) ::= assignableNoNl(M).                { E = M;                                                                      }
simpleExprNoNl(E) ::= unaryOpNoNl(M).                   { E = M;                                                                      }
simpleExprNoNl(E) ::= blockCallNoNl(C).                 { E = C;                                                                      }
simpleExprNoNl(E) ::= blockNoNl(B).                     { E = B;                                                                      }
simpleExprNl(E) ::= parenExprNl(PE).                    { E = PE;                                                                     }
simpleExprNl(E) ::= literalNl(L).                       { E = L;                                                                      }
simpleExprNl(E) ::= constantNl(L).                      { E = L;                                                                      }
simpleExprNl(E) ::= unaryMsgNl(M).                      { E = M;                                                                      }
//simpleExprNl(E) ::= variableNl(L).                      { E = L;                                                                      }
//simpleExprNl(E) ::= subscriptNl(L).                     { E = L;                                                                      }
//simpleExprNl(E) ::= propertyNl(L).                      { E = L;                                                                      }
simpleExprNl(E) ::= assignableNl(M).                    { E = M;                                                                      }
simpleExprNl(E) ::= unaryOpNl(M).                       { E = M;                                                                      }
simpleExprNl(E) ::= blockCallNl(C).                     { E = C;                                                                      }
simpleExprNl(E) ::= blockNl(B).                         { E = B;                                                                      }


//
// Messages ---------------------------------------------------------------------------------------------------------------------------
//

// Unary messages
unaryMsgNoNl(M) ::= unaryRcvr(R) unarySelNoNl(S).       { M = [TQNodeMessage unaryMessageWithReceiver:R selector:S];                  }
unarySelNoNl(U) ::= IDENT(T).                           { U = [T value];                                                              }
unarySelNoNl(U) ::= CONST(T).                           { U = [T value];                                                              }
unarySelNoNl(U) ::= SELF.                               { U = @"self";                                                                }

unaryMsgNl(M)   ::= unaryRcvr(R) unarySelNl(S).         { M = [TQNodeMessage unaryMessageWithReceiver:R selector:S];                  }
unarySelNl(U)   ::= IDENTNL(T).                         { U = [T value];                                                              }
unarySelNl(U)   ::= CONSTNL(T).                         { U = [T value];                                                              }
unarySelNl(U)   ::= SELFNL.                             { U = @"self";                                                                }


// Keyword messages
kwdMsgNoNl(M) ::= kwdRcvr(R) selPartsNoNl(SP).          { M = [TQNodeMessage nodeWithReceiver:R arguments:SP];                        }
kwdMsgNl(M)   ::= kwdRcvr(R) selPartsNl(SP).            { M = [TQNodeMessage nodeWithReceiver:R arguments:SP];                        }

selParts(ARR)     ::= .                                 { ARR = [NSMutableArray array];                                               }
selParts(ARR)     ::= selParts(T) selPart(SP).          { ARR = T; [ARR addObject:SP];                                                }
selPartsNl(ARR)   ::= selParts(T) selPartNl(SP).        { ARR = T; [ARR addObject:SP];                                                }
selPartsNoNl(ARR) ::= selParts(T) selPartNoNl(SP).      { ARR = T; [ARR addObject:SP];                                                }

selPart(SP)     ::= SELPART(T) msgArg(A).               { SP = [TQNodeArgument nodeWithPassedNode:A selectorPart:[T value]];          }
selPartNoNl(SP) ::= SELPART(T) msgArgNoNl(A).           { SP = [TQNodeArgument nodeWithPassedNode:A selectorPart:[T value]];          }
selPartNl(SP)   ::= SELPART(T) msgArgNl(A).             { SP = [TQNodeArgument nodeWithPassedNode:A selectorPart:[T value]];          }

unaryRcvr(R) ::= simpleExprNoNl(L).                     { R = L;                                                                      }

kwdRcvr(R)   ::= simpleExprNoNl(T).                     { R = T;                                                                      }
kwdRcvr(A)   ::= opNoNl(O).                             { A = O;                                                                      }

msgArg(A) ::= msgArgNoNl(T).                            { A = T;                                                                      }
msgArg(A) ::= msgArgNl(T).                              { A = T;                                                                      }

msgArgNoNl(A) ::= simpleExprNoNl(E).                    { A = E;                                                                      }
msgArgNoNl(A) ::= opNoNl(E).                            { A = E;                                                                      }
msgArgNl(A) ::= simpleExprNl(E).                        { A = E;                                                                      }
msgArgNl(A) ::= opNl(E).                                { A = E;                                                                      }

// Cascaded messages
cascadeNoNl(C) ::= noAsgnExprNoNl(E) SEMICOLON unarySelNoNl(S). {
    if([E isKindOfClass:[TQNodeMessage class]])
        C = E;
    else
        C = [TQNodeMessage unaryMessageWithReceiver:E selector:@"self"];
    [[C cascadedMessages] addObject:[TQNodeMessage unaryMessageWithReceiver:nil selector:S]];
}
cascadeNoNl(C) ::= noAsgnExprNoNl(E) SEMICOLON selPartsNoNl(SP). {
    if([E isKindOfClass:[TQNodeMessage class]])
        C = E;
    else
        C = [TQNodeMessage unaryMessageWithReceiver:E selector:@"self"];
    [[C cascadedMessages] addObject:[TQNodeMessage nodeWithReceiver:nil arguments:SP]];
}
cascadeNl(C) ::= noAsgnExprNoNl(E) SEMICOLON unarySelNl(S). {
    if([E isKindOfClass:[TQNodeMessage class]])
        C = E;
    else
        C = [TQNodeMessage unaryMessageWithReceiver:E selector:@"self"];
    [[C cascadedMessages] addObject:[TQNodeMessage unaryMessageWithReceiver:nil selector:S]];
}
cascadeNl(C) ::= noAsgnExprNoNl(E) SEMICOLON selPartsNl(SP). {
    if([E isKindOfClass:[TQNodeMessage class]])
        C = E;
    else
        C = [TQNodeMessage unaryMessageWithReceiver:E selector:@"self"];
    [[C cascadedMessages] addObject:[TQNodeMessage nodeWithReceiver:nil arguments:SP]];
}


//
// Flow Control -----------------------------------------------------------------------------------------------------------------------
//

body(B) ::= bodyNl(T).             { B = T;                                                                                           }
body(B) ::= bodyNoNl(T).           { B = T;                                                                                           }

bodyNoNl(B) ::= exprNoNl(S).       { B = [S isKindOfClass:[TQNodeBlock class]] ? [S statements] : [NSMutableArray arrayWithObject:S]; }
bodyNoNl(B) ::= breakNoNl(S).      { B = [NSMutableArray arrayWithObject:S];                                                          }
bodyNoNl(B) ::= skipNoNl(S).       { B = [NSMutableArray arrayWithObject:S];                                                          }
bodyNoNl(B) ::= waitNoNl(S).       { B = [NSMutableArray arrayWithObject:S];                                                          }
bodyNoNl(B) ::= retNoNl(S).        { B = [NSMutableArray arrayWithObject:S];                                                          }
bodyNl(B)   ::= exprNl(S).         { B = [S isKindOfClass:[TQNodeBlock class]] ? [S statements] : [NSMutableArray arrayWithObject:S]; }
bodyNl(B)   ::= breakNl(S).        { B = [NSMutableArray arrayWithObject:S];                                                          }
bodyNl(B)   ::= skipNl(S).         { B = [NSMutableArray arrayWithObject:S];                                                          }
bodyNl(B)   ::= waitNl(S).         { B = [NSMutableArray arrayWithObject:S];                                                          }
bodyNl(B)   ::= retNl(S).          { B = [NSMutableArray arrayWithObject:S];                                                          }

elseBody(B) ::= bodyNl(T).         { B = T;                                                                                           }
elseBody(B) ::= cond(T).           { B = [NSMutableArray arrayWithObject:T];                                                          }


cond(I) ::= IF|UNLESS(T) expr(C) blockNl(IST).          { I = [CONDKLS(T) nodeWithCondition:C
                                                                               ifStatements:[IST statements]
                                                                             elseStatements:nil];                                     }
cond(I) ::= IF|UNLESS(T) expr(C) block(IST)
            ELSE elseBody(EST).                         { I = [CONDKLS(T) nodeWithCondition:C
                                                                               ifStatements:[IST statements]
                                                                             elseStatements:EST];                                     }
cond(I) ::= IF|UNLESS(T) expr(C) THEN bodyNl(IST).      { I = [CONDKLS(T) nodeWithCondition:C ifStatements:IST elseStatements:nil];   }
cond(I) ::= IF|UNLESS(T) expr(C) THEN body(IST)
            ELSE elseBody(EST).                         { I = [CONDKLS(T) nodeWithCondition:C ifStatements:IST elseStatements:EST];   }
cond(I) ::= bodyNoNl(IST) IF|UNLESS(T) exprNl(C).       { I = [CONDKLS(T) nodeWithCondition:C ifStatements:IST elseStatements:nil];   }


ternOpNoNl(O) ::= operandNoNl(C)
                  TERNIF operand(A)
                  TERNELSE operandNoNl(B).              { O = [TQNodeTernaryOperator nodeWithCondition:C ifExpr:A else:B];            }
ternOpNl(O) ::= operandNoNl(C)
                TERNIF operand(A)
                TERNELSE operandNl(B).                  { O = [TQNodeTernaryOperator nodeWithCondition:C ifExpr:A else:B];            }

loop(I) ::= WHILE|UNTIL(T) expr(C) blockNl(ST).         { I = [LOOPKLS(T) nodeWithCondition:C statements:[ST statements]];            }
loop(I) ::= bodyNoNl(ST) WHILE|UNTIL(T) exprNl(C).      { I = [LOOPKLS(T) nodeWithCondition:C statements:ST];                         }
loop(I) ::= WHILE|UNTIL(T) expr(C) DO bodyNl(ST).      { I = [LOOPKLS(T) nodeWithCondition:C statements:ST];   }

statement(S) ::= breakNl(B).                            { S = B;                                                                      }
statement(S) ::= skipNl(SK).                            { S = SK;                                                                     }

breakNoNl(B) ::= BREAK.                                 { B = [TQNodeBreak node];                                                     }
breakNl(B)   ::= BREAKNL.                               { B = [TQNodeBreak node];                                                     }
skipNoNl(S)  ::= SKIP.                                  { S = [TQNodeSkip node];                                                      }
skipNl(S)    ::= SKIPNL.                                { S = [TQNodeSkip node];                                                      }


//
// Concurrency Primitives -------------------------------------------------------------------------------------------------------------
//

asyncNoNl(A) ::= ASYNC simpleExprNoNl(B).               { A = [TQNodeAsync nodeWithExpression:B];                                     }
asyncNl(A) ::= ASYNC simpleExprNl(B).                   { A = [TQNodeAsync nodeWithExpression:B];                                     }

waitNoNl(A) ::= WAIT.                                   { A = [TQNodeWait node];                                                      }
waitNl(A)   ::= WAITNL.                                 { A = [TQNodeWait node];                                                      }
whenFinished(A) ::= WHENFINISHED simpleExprNl(B).       { A = [TQNodeWhenFinished nodeWithExpression:B];                              }
lock(A) ::= LOCK expr(C) blockNl(ST).                   { A = [TQNodeLock nodeWithCondition:C]; [A setStatements:[ST statements]];    }


//
// Memory Management Primitives -------------------------------------------------------------------------------------------------------
//

collect(C) ::= COLLECT bodyNl(B).                       { C = [TQNodeCollect node]; [C setStatements:B];                              }


//
// Import Directive -------------------------------------------------------------------------------------------------------------------
//

import(I) ::= IMPORT STRNL(P).                          { I = [TQNodeImport nodeWithPath:[P value]];                                  }
import(I) ::= IMPORT STR(P) PERIOD.                     { I = [TQNodeImport nodeWithPath:[P value]];                                  }


//
// Block Definitions ------------------------------------------------------------------------------------------------------------------
//

block(B)   ::= blockNoNl(T).                            { B = T;                                                                      }
block(B)   ::= blockNl(T).                              { B = T;                                                                      }

blockNl(B) ::= LBRACE statements(S) RBRACENL.           { B = [TQNodeBlock node]; [B setStatements:S];                                }
blockNl(B) ::= LBRACE blockArgs(A) PIPE statements(S) RBRACENL. {
    B = [TQNodeBlock nodeWithArguments:A statements:S];
}

blockNl(B) ::= backtick expr(E) BACKTICKNL.        { B = [TQNodeBlock node]; [[B statements] addObject:E]; [B setIsCompactBlock:YES]; }
blockNl(B) ::= backtick blockArgs(A) PIPE expr(E) BACKTICKNL. {
    B = [TQNodeBlock nodeWithArguments:A statement:E];
    [B setIsCompactBlock:YES];
}

blockNoNl(B) ::= LBRACE statements(S) RBRACE.          { B = [TQNodeBlock node]; [B setStatements:S];                                 }
blockNoNl(B) ::= LBRACE  blockArgs(A) PIPE statements(S) RBRACE. {
    B = [TQNodeBlock nodeWithArguments:A statements:S];
}

blockNoNl(B) ::= backtick expr(E) BACKTICK.        { B = [TQNodeBlock node]; [[B statements] addObject:E]; [B setIsCompactBlock:YES]; }
blockNoNl(B) ::= backtick blockArgs(A) PIPE expr(E) BACKTICK. {
    B = [TQNodeBlock nodeWithArguments:A statement:E];
    [B setIsCompactBlock:YES];
}

// This rule engages in some dark trickery in order to avoid a conflict with the assign statement (It's also not DRY => TODO: Clean this up)
blockArgs(A) ::= assignLhs(T).                                {
    A = [NSMutableArray arrayWithCapacity:[T count]];
    for(TQNodeVariable *n in T) {
        TQAssert([n isKindOfClass:[TQNodeVariable class]], @"Syntax Error: %@ is not a valid argument name", n);
        [A addObject:[TQNodeArgumentDef nodeWithName:[n name]]];
    }
}
blockArgs(A) ::= assignNoNl(ASS).                             {
    TQNodeAssignOperator *ass = ASS;
    TQAssert([ass type] == kTQOperatorAssign, @"Syntax Error: Invalid operator type for default argument");
    A = [NSMutableArray arrayWithCapacity:[[ass left] count] + [[ass right] count] - 1];
    for(TQNodeVariable *n in [ass left]) {
        TQAssert([n isKindOfClass:[TQNodeVariable class]], @"Syntax Error: %@ is not a valid argument name", n);
        [A addObject:[TQNodeArgumentDef nodeWithName:[n name]]];
    }
    [[A lastObject] setDefaultArgument:[[ass right] objectAtIndex:0]];
    [[ass right] removeObjectAtIndex:0];
    for(TQNodeVariable *n in [ass right]) {
        TQAssert([n isKindOfClass:[TQNodeVariable class]], @"Syntax Error: %@ is not a valid argument name", n);
        [A addObject:[TQNodeArgumentDef nodeWithName:[n name]]];
    }
}
blockArgs(A) ::= assignNoNl(ASS) ASSIGN noAsgnExprNoNl(DEF).  {
    TQNodeAssignOperator *ass = ASS;
    TQAssert([ass type] == kTQOperatorAssign, @"Syntax Error: Invalid operator type for default argument");
    A = [NSMutableArray arrayWithCapacity:[[ass left] count] + [[ass right] count] - 1];
    for(TQNodeVariable *n in [ass left]) {
        TQAssert([n isKindOfClass:[TQNodeVariable class]], @"Syntax Error: %@ is not a valid argument name", n);
        [A addObject:[TQNodeArgumentDef nodeWithName:[n name]]];
    }
    [[A lastObject] setDefaultArgument:[[ass right] objectAtIndex:0]];
    [[ass right] removeObjectAtIndex:0];
    for(TQNodeVariable *n in [ass right]) {
        TQAssert([n isKindOfClass:[TQNodeVariable class]], @"Syntax Error: %@ is not a valid argument name", n);
        [A addObject:[TQNodeArgumentDef nodeWithName:[n name]]];
    }
    [[A lastObject] setDefaultArgument:DEF];
}
blockArgs(A) ::= assignNoNl(ASS) ASSIGN noAsgnExprNoNl(DEF) COMMA blockArgs(R). {
    TQNodeAssignOperator *ass = ASS;
    TQAssert([ass type] == kTQOperatorAssign, @"Syntax Error: Invalid operator type for default argument");
    A = [NSMutableArray arrayWithCapacity:[[ass left] count] + ([[ass right] count] - 1) + [R count]];
    for(TQNodeVariable *n in [ass left]) {
        TQAssert([n isKindOfClass:[TQNodeVariable class]], @"Syntax Error: %@ is not a valid argument name", n);
        [A addObject:[TQNodeArgumentDef nodeWithName:[n name]]];
    }
    [[A lastObject] setDefaultArgument:[[ass right] objectAtIndex:0]];
    [[ass right] removeObjectAtIndex:0];
    for(TQNodeVariable *n in [ass right]) {
        TQAssert([n isKindOfClass:[TQNodeVariable class]], @"Syntax Error: %@ is not a valid argument name", n);
        [A addObject:[TQNodeArgumentDef nodeWithName:[n name]]];
    }
    [[A lastObject] setDefaultArgument:DEF];
    [A addObjectsFromArray:R];
}

//
// Block Calls ------------------------------------------------------------------------------------------------------------------------
//

blockCallNoNl(C)  ::= accessableNoNl(A) LPAREN callArgs(ARGS) RPAREN. { C = [TQNodeCall nodeWithCallee:A]; [C setArguments:ARGS];     }
blockCallNl(C)  ::= accessableNoNl(A) LPAREN callArgs(ARGS) RPARENNL. { C = [TQNodeCall nodeWithCallee:A]; [C setArguments:ARGS];     }

callArg(L)    ::= noAsgnExprNoNl(E).                                  { L = E;                                                        }
callArg(L)    ::= simpleAssign(E).                                    { L = E;                                                        }

callArgs(L)    ::= .                                                  { L = [NSMutableArray array];                                   }
callArgs(L)    ::= callArg(O).                                        { L = [NSMutableArray arrayWithObject:O];                       }
callArgs(L)    ::= callArgs(O) COMMA callArg(E).                      { L = O; [L addObject:E];                                       }


//
// Class definitions
//

statement(S) ::= class(C). { S = C; }
class(C) ::= HASH classDef(CD) LBRACE
               onloadMessages(OL)
               methods(M)
             RBRACENL.                                 { C = CD;
                                                         for(TQNodeMessage *msg in OL) {
                                                             msg.receiver = C;
                                                             [[(TQNodeClass *)C onloadMessages] addObject:msg];
                                                         }
                                                         for(TQNodeMethod *m in M) {
                                                             if([m type] == kTQInstanceMethod)
                                                                 [(NSMutableArray *)[C instanceMethods] addObject:m];
                                                             else
                                                                 [(NSMutableArray *)[C classMethods] addObject:m];
                                                         }                                                                            }

classDef(D) ::= constant(N).                           { D = [TQNodeClass nodeWithName:[N value]];                                    }
classDef(D) ::= constant(N) LESSER constant(SN).       { D = [TQNodeClass nodeWithName:[N value]]; [D setSuperClassName:[SN value]];  }

methods(MS) ::= .                                      { MS = [NSMutableArray array];                                                 }
methods(MS) ::= methods(O) method(M).                  { MS = O; [MS addObject:M];                                                    }

method(M)   ::= MINUS|PLUS(TY) selDef(SEL) blockNl(B). { M = [TQNodeMethod nodeWithType:[TY id] == MINUS ? kTQInstanceMethod
                                                                                                         : kTQClassMethod];
                                                         for(TQNodeArgumentDef *arg in SEL)
                                                            [M addArgument:arg error:nil];
                                                         [M setIsCompactBlock:[B isCompactBlock]];
                                                         [M setStatements:[B statements]];                                            }

selDef(SD) ::= uSelDef(T).                             { SD = [NSMutableArray arrayWithObject:T];                                     }
selDef(SD) ::= kSelDef(T).                             { SD = T;                                                                      }

uSelDef(SD) ::= IDENT|IDENTNL|CONST|CONSTNL(S).        { SD = [TQNodeMethodArgumentDef nodeWithName:nil selectorPart:[S value]];      }

kSelDef(SD) ::= rSelDef(T).                            { SD = T;                                                                      }
kSelDef(SD) ::= rSelDef(T) oSelDef(TT).                { SD = T; [SD addObjectsFromArray:TT];                                         }

// Required keyword selector parts
rSelDef(SD) ::= kSelPart(P).                           { SD = [NSMutableArray arrayWithObject:P];                                     }
rSelDef(SD) ::= kSelDef(O) kSelPart(P).                { SD = O; [SD addObject:P];                                                    }
// Optional keyword selector parts
oSelDef(SD) ::= LBRACKET oSelParts(T) RBRACKET|RBRACKETNL. { SD = T;                                                                  }
oSelParts(SD) ::= oSelPart(P).                         { SD = [NSMutableArray arrayWithObject:P];                                     }
oSelParts(SD) ::= oSelParts(O) oSelPart(P).              { SD = O; [SD addObject:P];                                                    }

kSelPart(SD) ::= SELPART(S) IDENT|IDENTNL(N).          { SD = [TQNodeMethodArgumentDef nodeWithName:[N value] selectorPart:[S value]];}
oSelPart(SD) ::= kSelPart(T).                          { SD = T; [SD setDefaultArgument:[TQNodeNil node]];                            }
oSelPart(SD) ::= kSelPart(T) ASSIGN msgArg(E).           { SD = T; [SD setDefaultArgument:E];                                           }

onloadMessages(MS) ::= .                               { MS = [NSMutableArray array];                                                 }
onloadMessages(MS) ::= onloadMessages(O) onloadMessage(M). { MS = O;  [MS addObject:M];                                               }
onloadMessage(M) ::= olMsgBeg(B) selPartNl(SP).        { [B addObject:SP]; M = [TQNodeMessage nodeWithReceiver:nil arguments:B];      }
olMsgBeg(M) ::= .                                      { M = [NSMutableArray array];                                                  }
olMsgBeg(M) ::= olMsgBeg(T) selPartNoNl(SP).           { M = T; [M addObject:SP];                                                     }

//
// Operators --------------------------------------------------------------------------------------------------------------------------
//

// Precedence
%right ASSIGN.
%left  OR.
%left  AND.
%left  EQUAL INEQUAL GREATER LESSER GEQUAL LEQUAL.
%left  PLUS MINUS.
%left  ASTERISK FSLASH PERCENT.
%left  INCR DECR LUNARY.
%right CARET RUNARY.
%right LBRACKET RBRACKET.

operand(O)     ::= operandNoNl(T).                      { O = T;                                                                      }
operand(O)     ::= operandNl(T).                        { O = T;                                                                      }

operandNoNl(O) ::= opNoNl(T).                           { O = T;                                                                      }
operandNoNl(O) ::= simpleExprNoNl(E).                   { O = E;                                                                      }
operandNl(O)   ::= opNl(T).                             { O = T;                                                                      }
operandNl(O)   ::= simpleExprNl(E).                     { O = E;                                                                      }


//Assignment
simpleAssign(A) ::= assignableNoNl(L) ASSIGN noAsgnExpr(R). { A = [TQNodeAssignOperator nodeWithTypeToken:ASSIGN left:[NSMutableArray arrayWithObject:L] right:[NSMutableArray arrayWithObject:R]];   }

assignNoNl(E) ::= assignLhs(A)
                  ASSIGN|ASSIGNADD|ASSIGNSUB|ASSIGNMUL|ASSIGNDIV|ASSIGNOR(OP)
                  assignRhsNoNl(B).                     { E = [TQNodeAssignOperator nodeWithTypeToken:[OP id] left:A right:B];   }

assignNl(E) ::= assignLhs(A)
                  ASSIGN|ASSIGNADD|ASSIGNSUB|ASSIGNMUL|ASSIGNDIV|ASSIGNOR(OP)
                  assignRhsNl(B).                       { E = [TQNodeAssignOperator nodeWithTypeToken:[OP id] left:A right:B];   }

assignLhs(L) ::= assignable(A).                     { L = [NSMutableArray arrayWithObject:A]; }
assignLhs(L) ::= assignLhs(O) COMMA assignable(E).  { L = O; [L addObject:E]; }

assignRhsNoNl(R) ::= assignRhsNoNl(O) COMMA rhsValNoNl(E). { R = O; [R addObject:E]; }
assignRhsNoNl(R) ::= rhsValNoNl(V).                     { R = [NSMutableArray arrayWithObject:V]; }
assignRhsNl(R)   ::= assignRhsNoNl(O) COMMA rhsValNl(E). { R = O; [R addObject:E]; }
assignRhsNl(R)   ::= rhsValNl(E).                       { R = [NSMutableArray arrayWithObject:E]; }

rhsValNoNl(V) ::= noAsgnExprNoNl(E). { V = E; }
rhsValNl(V)   ::= noAsgnExprNl(E).   { V = E; }


// Logic
opNoNl(O) ::= operandNoNl(A) AND|OR(OP) operandNoNl(B). { O = [TQNodeOperator nodeWithTypeToken:[OP id] left:A right:B];              }
opNl(O)   ::= operandNoNl(A) AND|OR(OP) operandNl(B).   { O = [TQNodeOperator nodeWithTypeToken:[OP id] left:A right:B];              }

// Arithmetic
opNoNl(O) ::= operandNoNl(A)
              PLUS|MINUS(OP)
              operandNoNl(B).                           { O = [TQNodeOperator nodeWithTypeToken:[OP id] left:A right:B];              }
opNoNl(O) ::= operandNoNl(A)
              ASTERISK|FSLASH|PERCENT(OP)
              operandNoNl(B).                           { O = [TQNodeOperator nodeWithTypeToken:[OP id] left:A right:B];              }
opNoNl(O) ::= operandNoNl(A) CARET(OP) operandNoNl(B).  { O = [TQNodeOperator nodeWithTypeToken:[OP id] left:A right:B];              }

opNl(O) ::= operandNoNl(A) PLUS|MINUS(OP) operandNl(B). { O = [TQNodeOperator nodeWithTypeToken:[OP id] left:A right:B];              }
opNl(O) ::= operandNoNl(A)
            ASTERISK|FSLASH|PERCENT(OP)
            operandNl(B).                               { O = [TQNodeOperator nodeWithTypeToken:[OP id] left:A right:B];              }
opNl(O) ::= operandNoNl(A) CARET(OP) operandNl(B).      { O = [TQNodeOperator nodeWithTypeToken:[OP id] left:A right:B];              }

// Unary operators
unaryOpNoNl(O) ::= MINUS accessableNoNl(A). [LUNARY]    { O = [TQNodeOperator nodeWithType:kTQOperatorUnaryMinus left:nil right:A];   }
unaryOpNoNl(O) ::= INCR  accessableNoNl(A). [LUNARY]    { O = [TQNodeOperator nodeWithType:kTQOperatorIncrement  left:nil right:A];   }
unaryOpNoNl(O) ::= accessableNoNl(A) INCR.  [RUNARY]    { O = [TQNodeOperator nodeWithType:kTQOperatorIncrement  left:A   right:nil]; }
unaryOpNoNl(O) ::= DECR accessableNoNl(A).  [LUNARY]    { O = [TQNodeOperator nodeWithType:kTQOperatorDecrement  left:nil right:A];   }
unaryOpNoNl(O) ::= accessableNoNl(A) DECR.  [RUNARY]    { O = [TQNodeOperator nodeWithType:kTQOperatorDecrement  left:A   right:nil]; }
unaryOpNoNl(O) ::= TILDE accessableNoNl(E). [LUNARY]    { O = [TQNodeWeak nodeWithValue:E];                                           }

unaryOpNl(O) ::= MINUS accessableNl(A).     [LUNARY]    { O = [TQNodeOperator nodeWithType:kTQOperatorUnaryMinus left:nil right:A];   }
unaryOpNl(O) ::= INCR  accessableNl(A).     [LUNARY]    { O = [TQNodeOperator nodeWithType:kTQOperatorIncrement  left:nil right:A];   }
unaryOpNl(O) ::= accessableNoNl(A) INCRNL.  [RUNARY]    { O = [TQNodeOperator nodeWithType:kTQOperatorIncrement  left:A   right:nil]; }
unaryOpNl(O) ::= DECR assignableNl(A).      [LUNARY]    { O = [TQNodeOperator nodeWithType:kTQOperatorDecrement  left:nil right:A];   }
unaryOpNl(O) ::= accessableNoNl(A) DECRNL.  [RUNARY]    { O = [TQNodeOperator nodeWithType:kTQOperatorDecrement  left:A   right:nil]; }
unaryOpNl(O) ::= TILDE accessableNl(E).     [LUNARY]    { O = [TQNodeWeak nodeWithValue:E];                                           }

// Comparisons
opNoNl(O) ::= operandNoNl(A)
              EQUAL|INEQUAL|GREATER|LESSER|GEQUAL|LEQUAL(OP)
              operandNoNl(B).                           { O = [TQNodeOperator nodeWithTypeToken:[OP id] left:A right:B];              }

opNl(O) ::= operandNoNl(A)
            EQUAL|INEQUAL|GREATER|LESSER|GEQUAL|LEQUAL(OP)
            operandNl(B).                               { O = [TQNodeOperator nodeWithTypeToken:[OP id] left:A right:B];              }


//
// Literals ---------------------------------------------------------------------------------------------------------------------------
//

literalNoNl(L) ::= NUMBER(T).                           { L = [TQNodeNumber nodeWithDouble:[[T value] doubleValue]];                  }
literalNoNl(L) ::= stringNoNl(S).                       { L = S;                                                                      }
literalNoNl(L) ::= arrayNoNl(A).                        { L = A;                                                                      }
literalNoNl(L) ::= dictNoNl(D).                         { L = D;                                                                      }
literalNoNl(L) ::= regexNoNl(D).                        { L = D;                                                                      }

literalNl(L)   ::= NUMBERNL(T).                         { L = [TQNodeNumber nodeWithDouble:[[T value] doubleValue]];                  }
literalNl(L)   ::= stringNl(S).                         { L = S;                                                                      }
literalNl(L)   ::= arrayNl(A).                          { L = A;                                                                      }
literalNl(L)   ::= dictNl(D).                           { L = D;                                                                      }
literalNl(L)   ::= regexNl(D).                          { L = D;                                                                      }


// Arrays
arrayNoNl(A) ::= LBRACKET RBRACKET.                     { A = [TQNodeArray node];                                                     }
arrayNoNl(A) ::= LBRACKET aryEls(EL) RBRACKET.          { A = [TQNodeArray node]; [A setItems:EL];                                    }
arrayNl(A)   ::= LBRACKET RBRACKETNL.                   { A = [TQNodeArray node];                                                     }
arrayNl(A)   ::= LBRACKET aryEls(EL) RBRACKETNL.        { A = [TQNodeArray node]; [A setItems:EL];                                    }

aryEls(EL)   ::= aryEls(O) COMMA noAsgnExpr(E).         { EL = O; [EL addObject:E];                                                   }
aryEls(EL)   ::= noAsgnExpr(E).                         { EL = [NSMutableArray arrayWithObject:E];                                    }


// Dictionaries
dictNoNl(D) ::= LBRACE RBRACE.                          { D = [TQNodeDictionary node];                                                }
dictNoNl(D) ::= LBRACE dictEls(EL) RBRACE.              { D = [TQNodeDictionary node]; [D setItems:EL];                               }
dictNl(D)   ::= LBRACE RBRACENL.                        { D = [TQNodeDictionary node];                                                }
dictNl(D)   ::= LBRACE dictEls(EL) RBRACENL.            { D = [TQNodeDictionary node]; [D setItems:EL];                               }

dictEls(ELS) ::= dictEls(O) COMMA  dictEl(EL).          { ELS = O; for(id k in EL) [ELS setObject:[EL objectForKey:k] forKey:k];      }
dictEls(ELS) ::= dictEl(EL).                            { ELS = EL;                                                                   }
dictEl(EL)  ::= noAsgnExpr(K) DICTSEP noAsgnExpr(V).    { EL = [[NSMapTable new] autorelease]; [EL setObject:V forKey:K];             }

// Strings
stringNoNl(S) ::= CONSTSTR(V).                          { S = [TQNodeConstString nodeWithString:(NSMutableString *)[V value]];        }
stringNoNl(S) ::= STR(V).                               { S = [TQNodeString nodeWithString:(NSMutableString *)[V value]];             }
stringNoNl(S) ::= LSTR(L) inStr(M) RSTR(R).             { S = [TQNodeString nodeWithLeft:[L value] embeds:M right:[R value]];         }

stringNl(S)   ::= CONSTSTRNL(V).                        { S = [TQNodeConstString nodeWithString:(NSMutableString *)[V value]];        }
stringNl(S)   ::= STRNL(V).                             { S = [TQNodeString nodeWithString:(NSMutableString *)[V value]];             }
stringNl(S)   ::= LSTR(L) inStr(M) RSTRNL(R).           { S = [TQNodeString nodeWithLeft:[L value] embeds:M right:[R value]];         }

inStr(M) ::= inStr(O) MSTR(S) expr(E).                  { M = O; [M addObject:[S value]]; [M addObject:E];                            }
inStr(M) ::= expr(E).                                   { M = [NSMutableArray arrayWithObject:E];                                     }

// Regular expressions
regexNoNl(R) ::= REGEX(T).                             { R = [TQNodeRegex nodeWithPattern:[T value]];                                }
regexNl(R)   ::= REGEXNL(T).                           { R = [TQNodeRegex nodeWithPattern:[T value]];                                }

//
// Variables, Identifiers & Built-in Constants
//

//identifier(I)   ::= IDENT(T).                           { I = [T value];                                                              }
//identifier(I)   ::= IDENTNL(T).                         { I = [T value];                                                              }

constant(C)     ::= constantNoNl(T).                    { C = T;                                                                      }
constant(C)     ::= constantNl(T).                      { C = T;                                                                      }
constantNoNl(C) ::= CONST(T).                           { C = [TQNodeConstant nodeWithString:(NSMutableString *)[T value]];           }
constantNl(C)   ::= CONSTNL(T).                         { C = [TQNodeConstant nodeWithString:(NSMutableString *)[T value]];           }

variableNoNl(V) ::= IDENT(T).                           { V = [TQNodeVariable nodeWithName:[T value]];                                }
variableNoNl(V) ::= SELF.                               { V = [TQNodeSelf node];                                                      }
variableNoNl(V) ::= SUPER.                              { V = [TQNodeSuper node];                                                     }
variableNoNl(V) ::= VALID.                              { V = [TQNodeValid node];                                                     }
variableNoNl(V) ::= YESTOK.                             { V = [TQNodeValid node];                                                     }
variableNoNl(V) ::= NOTOK.                              { V = [TQNodeNil node];                                                       }
variableNoNl(V) ::= NIL.                                { V = [TQNodeNil node];                                                       }
variableNoNl(V) ::= NOTHING.                            { V = [TQNodeNothing node];                                                   }
variableNoNl(V) ::= vaargNoNl(T).                       { V = T;                                                                      }

variableNl(V)   ::= IDENTNL(T).                         { V = [TQNodeVariable nodeWithName:[T value]];                                }
variableNl(V)   ::= SELFNL.                             { V = [TQNodeSelf node];                                                      }
variableNl(V)   ::= SUPERNL.                            { V = [TQNodeSuper node];                                                     }
variableNl(V)   ::= VALIDNL.                            { V = [TQNodeValid node];                                                     }
variableNl(V)   ::= YESTOKNL.                           { V = [TQNodeValid node];                                                     }
variableNl(V)   ::= NOTOKNL.                            { V = [TQNodeNil node];                                                       }
variableNl(V)   ::= NILNL.                              { V = [TQNodeNil node];                                                       }
variableNl(V)   ::= NOTHINGNL.                          { V = [TQNodeNothing node];                                                   }
variableNl(V)   ::= vaargNl(T).                         { V = T;                                                                      }

//vaarg(V)        ::= vaargNoNl(T).                       { V = T;                                                                      }
//vaarg(V)        ::= vaargNl(T).                         { V = T;                                                                      }
vaargNoNl(V)    ::= VAARG.                              { V = [TQNodeVariable nodeWithName:@"..."];                                   }
vaargNl(V)      ::= VAARGNL.                            { V = [TQNodeVariable nodeWithName:@"..."];                                   }

// Accessables (Simple values; needs to be merged with simpleExpr when I resolve the conflicts that occur)
accessableNoNl(A) ::= variableNoNl(V).                  { A = V;                                                                      }
accessableNoNl(A) ::= literalNoNl(V).                   { A = V;                                                                      }
accessableNoNl(A) ::= constantNoNl(V).                  { A = V;                                                                      }
accessableNoNl(A) ::= parenExprNoNl(V).                 { A = V;                                                                      }
accessableNoNl(A) ::= blockNoNl(V).                     { A = V;                                                                      }
accessableNoNl(A) ::= subscriptNoNl(V).                 { A = V;                                                                      }
accessableNoNl(A) ::= propertyNoNl(V).                  { A = V;                                                                      }

accessableNl(A) ::= variableNl(V).                      { A = V;                                                                      }
accessableNl(A) ::= literalNl(V).                       { A = V;                                                                      }
accessableNl(A) ::= constantNl(V).                      { A = V;                                                                      }
accessableNl(A) ::= parenExprNl(V).                     { A = V;                                                                      }
accessableNl(A) ::= blockNl(V).                         { A = V;                                                                      }
accessableNl(A) ::= subscriptNl(V).                     { A = V;                                                                      }
accessableNl(A) ::= propertyNl(V).                      { A = V;                                                                      }

// Assignables
assignable(V)     ::= assignableNoNl(T).                { V = T;                                                                      }
assignable(V)     ::= assignableNl(T).                  { V = T;                                                                      }

assignableNoNl(V) ::= variableNoNl(T).                  { V = T;                                                                      }
assignableNoNl(V) ::= subscriptNoNl(T).                 { V = T;                                                                      }
assignableNoNl(V) ::= propertyNoNl(T).                  { V = T;                                                                      }
assignableNl(V)   ::= variableNl(T).                    { V = T;                                                                      }
assignableNl(V)   ::= subscriptNl(T).                   { V = T;                                                                      }
assignableNl(V)   ::= propertyNl(T).                    { V = T;                                                                      }

// Subscripts
subscriptNoNl(S) ::= accessableNoNl(L)
                     LBRACKET noAsgnExpr(E) RBRACKET.   { S = [TQNodeOperator nodeWithType:kTQOperatorSubscript left:L right:E];      }
subscriptNl(S)   ::= accessableNoNl(L)
                     LBRACKET noAsgnExpr(E) RBRACKETNL. { S = [TQNodeOperator nodeWithType:kTQOperatorSubscript left:L right:E];      }

// Properties
propertyNoNl(P) ::= accessableNoNl(R) HASH IDENT(I).    { P = [TQNodeMemberAccess nodeWithReceiver:R property:[I value]];             }
propertyNl(P)   ::= accessableNoNl(R) HASH IDENTNL(I).  { P = [TQNodeMemberAccess nodeWithReceiver:R property:[I value]];             }
propertyNoNl(P) ::=                   HASH IDENT(I).    { P = [TQNodeMemberAccess nodeWithReceiver:[TQNodeSelf node] property:[I value]]; }
propertyNl(P)   ::=                   HASH IDENTNL(I).  { P = [TQNodeMemberAccess nodeWithReceiver:[TQNodeSelf node] property:[I value]]; }

// Misc
backtick        ::= BACKTICK|BACKTICKNL.

//
// Error Handling  --------------------------------------------------------------------------------------------------------------------
//

%syntax_error {
    SyntaxError(kTQGenericError);
}


// ------------------------------------------------------------------------------------------------------------------------------------

%include {
#import <Tranquil/CodeGen/CodeGen.h>
#import <Tranquil/Shared/TQDebug.h>

#define SyntaxError(aCode) do { \
    NSString *reason = [NSString stringWithFormat:@"Syntax error: near '%@' on line %d", [TOKEN value], [TOKEN line]]; \
    NSDictionary *info = [NSDictionary dictionaryWithObject:reason forKey:NSLocalizedDescriptionKey]; \
    state->syntaxError = [NSError errorWithDomain:kTQSyntaxErrorDomain \
                                             code:aCode \
                                         userInfo:info]; \
   [NSException raise:@"Syntax Error" format:nil]; \
} while(0)

#define CONDKLS(T) ([T id] == IF    ? [TQNodeIfBlock class]    : [TQNodeUnlessBlock class])
#define LOOPKLS(T) ([T id] == WHILE ? [TQNodeWhileBlock class] : [TQNodeUntilBlock class])

// TQNode* methods to keep grammar actions to a single line

@interface TQNodeAssignOperator (TQParserAdditions)
+ (TQNodeAssignOperator *)nodeWithTypeToken:(int)token left:(NSMutableArray *)left right:(NSMutableArray *)right;
@end
@implementation TQNodeAssignOperator (TQParserAdditions)
+ (TQNodeAssignOperator *)nodeWithTypeToken:(int)token left:(NSMutableArray *)left right:(NSMutableArray *)right
{
    int op;
    switch(token) {
        case ASSIGN:    op = kTQOperatorAssign;         break;
        case ASSIGNADD: op = kTQOperatorAdd;            break;
        case ASSIGNSUB: op = kTQOperatorSubtract;       break;
        case ASSIGNMUL: op = kTQOperatorMultiply;       break;
        case ASSIGNDIV: op = kTQOperatorDivide;         break;
        case ASSIGNOR:  op = kTQOperatorOr;             break;
        default:       TQAssert(NO, @"Unknown operator token %d", token);
    }
    return [self nodeWithType:op left:left right:right];
}
@end

@interface TQNodeOperator (TQParserAdditions)
+ (TQNodeOperator *)nodeWithTypeToken:(int)token left:(TQNode *)left right:(TQNode *)right;
@end
@implementation TQNodeOperator (TQParserAdditions)
+ (TQNodeOperator *)nodeWithTypeToken:(int)token left:(TQNode *)left right:(TQNode *)right
{
    int op;
    switch(token) {
        case PLUS:     op = kTQOperatorAdd;            break;
        case MINUS:    op = kTQOperatorSubtract;       break;
        case ASTERISK: op = kTQOperatorMultiply;       break;
        case FSLASH:   op = kTQOperatorDivide;         break;
        case PERCENT:  op = kTQOperatorModulo;         break;
        case CARET:    op = kTQOperatorExponent;       break;
        case EQUAL:    op = kTQOperatorEqual;          break;
        case INEQUAL:  op = kTQOperatorInequal;        break;
        case GREATER:  op = kTQOperatorGreater;        break;
        case LESSER:   op = kTQOperatorLesser;         break;
        case LEQUAL:   op = kTQOperatorLesserOrEqual;  break;
        case GEQUAL:   op = kTQOperatorGreaterOrEqual; break;
        case AND:      op = kTQOperatorAnd;            break;
        case OR:       op = kTQOperatorOr;             break;
        default:       TQAssert(NO, @"Unknown operator token %d", token);
    }
    return [self nodeWithType:op left:left right:right];
}
@end

@interface TQNodeBlock (TQParserAdditions)
+ (TQNodeBlock *)nodeWithArguments:(NSMutableArray *)args statement:(TQNode *)stmt;
+ (TQNodeBlock *)nodeWithArguments:(NSMutableArray *)args statements:(NSMutableArray *)statements;
@end
@implementation TQNodeBlock (TQParserAdditions)
+ (TQNodeBlock *)nodeWithArguments:(NSMutableArray *)args statement:(TQNode *)stmt;
{
    return [self nodeWithArguments:args statements:[NSMutableArray arrayWithObject:stmt]];
}
+ (TQNodeBlock *)nodeWithArguments:(NSMutableArray *)args statements:(NSMutableArray *)statements
{
    TQNodeBlock *ret = [TQNodeBlock node];

    for(TQNodeArgumentDef *arg in args) {
        if([[arg name] isEqualToString:@"..."]) {
            [ret setIsVariadic:YES];
            TQAssert(![arg defaultArgument], @"Syntax Error: '...' can't have a default value");
            NSUInteger idx = [args indexOfObject:arg];
            TQAssert(idx == ([args count] - 1), @"Syntax Error: No arguments can come after '...'");
        } else
            [ret addArgument:arg error:nil];
    }
    [ret setStatements:statements];

    return ret;
}
@end

@interface TQNodeMessage (TQParserAdditions)
+ (TQNodeMessage *)unaryMessageWithReceiver:(TQNode *)rcvr selector:(NSString *)sel;
+ (TQNodeMessage *)nodeWithReceiver:(TQNode *)rcvr arguments:(NSMutableArray *)args;
@end
@implementation TQNodeMessage (TQParserAdditions)
+ (TQNodeMessage *)nodeWithReceiver:(TQNode *)rcvr arguments:(NSMutableArray *)args
{
    TQNodeMessage *ret = [TQNodeMessage nodeWithReceiver:rcvr];
    ret.arguments = args;
    return ret;
}
+ (TQNodeMessage *)unaryMessageWithReceiver:(TQNode *)rcvr selector:(NSString *)sel
{
    TQNodeMessage *ret = [TQNodeMessage nodeWithReceiver:rcvr];
    [ret.arguments addObject:[TQNodeArgument nodeWithPassedNode:nil selectorPart:sel]];
    return ret;
}
@end

@interface TQNodeString (TQParserAdditions)
+ (TQNodeString *)nodeWithLeft:(NSString *)left embeds:(NSMutableArray *)embeds right:(NSString *)right;
@end
@implementation TQNodeString (TQParserAdditions)
+ (TQNodeString *)nodeWithLeft:(NSMutableString *)left embeds:(NSMutableArray *)embeds right:(NSMutableString *)right;
{
    TQNodeString *ret = [TQNodeString nodeWithString:left];
    for(int i = 0; i < [embeds count]; ++i) {
        if(i == 0 || i % 2 == 0) {
            [ret.value appendString:@"%@"];
            [ret.embeddedValues addObject:[embeds objectAtIndex:i]];
        } else
            [ret.value appendString:[embeds objectAtIndex:i]];
    }
    [ret.value appendString:right];
    return ret;
}
@end
}
