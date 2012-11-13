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

statements(SS) ::= statements(O) statement(S).          { SS = O; [(OFMutableArray *)SS addObject:S];                                 }
statements(SS) ::= statement(S).                        { SS = [OFMutableArray arrayWithObject:S];                                    }

statement(S) ::= exprNl(E).                             { S = E;                                                                      }
statement(S) ::= cond(C).                               { S = C;                                                                      }
statement(S) ::= loop(L).                               { S = L;                                                                      }
statement(S) ::= waitNl(W).                             { S = W;                                                                      }
statement(S) ::= whenFinished(W).                       { S = W;                                                                      }
statement(S) ::= lock(L).                               { S = L;                                                                      }
statement(S) ::= collect(C).                            { S = C;                                                                      }
statement(S) ::= import(I).                             { S = I;                                                                      }
statement(S) ::= retNl(I).                              { S = I;                                                                      }

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

selParts(ARR)     ::= .                                 { ARR = [OFMutableArray array];                                               }
selParts(ARR)     ::= selParts(T) selPart(SP).          { ARR = T; [(OFMutableArray *)ARR addObject:SP];                              }
selPartsNl(ARR)   ::= selParts(T) selPartNl(SP).        { ARR = T; [(OFMutableArray *)ARR addObject:SP];                              }
selPartsNoNl(ARR) ::= selParts(T) selPartNoNl(SP).      { ARR = T; [(OFMutableArray *)ARR addObject:SP];                              }

selPart(SP)     ::= SELPART(T) msgArg(A).               { SP = [TQNodeArgument nodeWithPassedNode:A selectorPart:[(TQToken *)T value]];          }
selPartNoNl(SP) ::= SELPART(T) msgArgNoNl(A).           { SP = [TQNodeArgument nodeWithPassedNode:A selectorPart:[(TQToken *)T value]];          }
selPartNl(SP)   ::= SELPART(T) msgArgNl(A).             { SP = [TQNodeArgument nodeWithPassedNode:A selectorPart:[(TQToken *)T value]];          }

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

bodyNoNl(B) ::= exprNoNl(S).       { B = [S isKindOfClass:[TQNodeBlock class]] ? [S statements] : [OFMutableArray arrayWithObject:S]; }
bodyNoNl(B) ::= breakNoNl(S).      { B = [OFMutableArray arrayWithObject:S];                                                          }
bodyNoNl(B) ::= skipNoNl(S).       { B = [OFMutableArray arrayWithObject:S];                                                          }
bodyNoNl(B) ::= waitNoNl(S).       { B = [OFMutableArray arrayWithObject:S];                                                          }
bodyNoNl(B) ::= retNoNl(S).        { B = [OFMutableArray arrayWithObject:S];                                                          }
bodyNl(B)   ::= exprNl(S).         { B = [S isKindOfClass:[TQNodeBlock class]] ? [S statements] : [OFMutableArray arrayWithObject:S]; }
bodyNl(B)   ::= breakNl(S).        { B = [OFMutableArray arrayWithObject:S];                                                          }
bodyNl(B)   ::= skipNl(S).         { B = [OFMutableArray arrayWithObject:S];                                                          }
bodyNl(B)   ::= waitNl(S).         { B = [OFMutableArray arrayWithObject:S];                                                          }
bodyNl(B)   ::= retNl(S).          { B = [OFMutableArray arrayWithObject:S];                                                          }

elseBody(B) ::= bodyNl(T).         { B = T;                                                                                           }
elseBody(B) ::= cond(T).           { B = [OFMutableArray arrayWithObject:T];                                                          }


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

import(I) ::= IMPORT STRNL(P).                          { I = [TQNodeImport nodeWithPath:[(TQToken *)P value]];                       }


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
    A = [OFMutableArray array];
    for(TQNodeVariable *n in T) {
        TQAssert([n isKindOfClass:[TQNodeVariable class]], @"Syntax Error: %@ is not a valid argument name", n);
        [(OFMutableArray *)A addObject:[TQNodeArgumentDef nodeWithName:[n name]]];
    }
}
blockArgs(A) ::= assignNoNl(ASS).                             {
    TQNodeAssignOperator *ass = ASS;
    TQAssert([ass type] == kTQOperatorAssign, @"Syntax Error: Invalid operator type for default argument");
    A = [OFMutableArray array];
    for(TQNodeVariable *n in [ass left]) {
        TQAssert([n isKindOfClass:[TQNodeVariable class]], @"Syntax Error: %@ is not a valid argument name", n);
        [(OFMutableArray *)A addObject:[TQNodeArgumentDef nodeWithName:[n name]]];
    }
    [[A lastObject] setDefaultArgument:[[ass right] objectAtIndex:0]];
    [[ass right] removeObjectAtIndex:0];
    for(TQNodeVariable *n in [ass right]) {
        TQAssert([n isKindOfClass:[TQNodeVariable class]], @"Syntax Error: %@ is not a valid argument name", n);
        [(OFMutableArray *)A addObject:[TQNodeArgumentDef nodeWithName:[n name]]];
    }
}
blockArgs(A) ::= assignNoNl(ASS) ASSIGN noAsgnExprNoNl(DEF).  {
    TQNodeAssignOperator *ass = ASS;
    TQAssert([ass type] == kTQOperatorAssign, @"Syntax Error: Invalid operator type for default argument");
    A = [OFMutableArray array];
    for(TQNodeVariable *n in [ass left]) {
        TQAssert([n isKindOfClass:[TQNodeVariable class]], @"Syntax Error: %@ is not a valid argument name", n);
        [(OFMutableArray *)A addObject:[TQNodeArgumentDef nodeWithName:[n name]]];
    }
    [[A lastObject] setDefaultArgument:[[ass right] objectAtIndex:0]];
    [[ass right] removeObjectAtIndex:0];
    for(TQNodeVariable *n in [ass right]) {
        TQAssert([n isKindOfClass:[TQNodeVariable class]], @"Syntax Error: %@ is not a valid argument name", n);
        [(OFMutableArray *)A addObject:[TQNodeArgumentDef nodeWithName:[n name]]];
    }
    [[A lastObject] setDefaultArgument:DEF];
}
blockArgs(A) ::= assignNoNl(ASS) ASSIGN noAsgnExprNoNl(DEF) COMMA blockArgs(R). {
    TQNodeAssignOperator *ass = ASS;
    TQAssert([ass type] == kTQOperatorAssign, @"Syntax Error: Invalid operator type for default argument");
    A = [OFMutableArray array];
    for(TQNodeVariable *n in [ass left]) {
        TQAssert([n isKindOfClass:[TQNodeVariable class]], @"Syntax Error: %@ is not a valid argument name", n);
        [(OFMutableArray *)A addObject:[TQNodeArgumentDef nodeWithName:[n name]]];
    }
    [[A lastObject] setDefaultArgument:[[ass right] objectAtIndex:0]];
    [[ass right] removeObjectAtIndex:0];
    for(TQNodeVariable *n in [ass right]) {
        TQAssert([n isKindOfClass:[TQNodeVariable class]], @"Syntax Error: %@ is not a valid argument name", n);
        [(OFMutableArray *)A addObject:[TQNodeArgumentDef nodeWithName:[n name]]];
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

callArgs(L)    ::= .                                                  { L = [OFMutableArray array];                                   }
callArgs(L)    ::= callArg(O).                                        { L = [OFMutableArray arrayWithObject:O];                       }
callArgs(L)    ::= callArgs(O) COMMA callArg(E).                      { L = O; [(OFMutableArray *)L addObject:E];                                       }


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
                                                                 [(OFMutableArray *)[C instanceMethods] addObject:m];
                                                             else
                                                                 [(OFMutableArray *)[C classMethods] addObject:m];
                                                         }                                                                            }

classDef(D) ::= constant(N).                           { D = [TQNodeClass nodeWithName:[(TQToken *)N value]];                         }
classDef(D) ::= constant(N) LESSER constant(SN).       { D = [TQNodeClass nodeWithName:[(TQToken *)N value]]; [D setSuperClassName:[(TQToken *)SN value]];  }

methods(MS) ::= .                                      { MS = [OFMutableArray array];                                                 }
methods(MS) ::= methods(O) method(M).                  { MS = O; [(OFMutableArray *)MS addObject:M];                                                    }

method(M)   ::= MINUS|PLUS(TY) selDef(SEL) blockNl(B). { M = [TQNodeMethod nodeWithType:[TY id] == MINUS ? kTQInstanceMethod
                                                                                                         : kTQClassMethod];
                                                         for(TQNodeArgumentDef *arg in SEL)
                                                            [M addArgument:arg error:nil];
                                                         [M setIsCompactBlock:[B isCompactBlock]];
                                                         [M setStatements:[B statements]];                                            }

selDef(SD) ::= uSelDef(T).                             { SD = [OFMutableArray arrayWithObject:T];                                     }
selDef(SD) ::= kSelDef(T).                             { SD = T;                                                                      }

uSelDef(SD) ::= IDENT|IDENTNL|CONST|CONSTNL(S).        { SD = [TQNodeMethodArgumentDef nodeWithName:nil selectorPart:[(TQToken *)S value]];      }

kSelDef(SD) ::= rSelDef(T).                            { SD = T;                                                                      }
kSelDef(SD) ::= rSelDef(T) oSelDef(TT).                { SD = T; [SD addObjectsFromArray:TT];                                         }

// Required keyword selector parts
rSelDef(SD) ::= kSelPart(P).                           { SD = [OFMutableArray arrayWithObject:P];                                     }
rSelDef(SD) ::= kSelDef(O) kSelPart(P).                { SD = O; [(OFMutableArray *)SD addObject:P];                                                    }
// Optional keyword selector parts
oSelDef(SD) ::= LBRACKET oSelParts(T) RBRACKET|RBRACKETNL. { SD = T;                                                                  }
oSelParts(SD) ::= oSelPart(P).                         { SD = [OFMutableArray arrayWithObject:P];                                     }
oSelParts(SD) ::= oSelParts(O) oSelPart(P).            { SD = O; [(OFMutableArray *)SD addObject:P];                                                    }

kSelPart(SD) ::= SELPART(S) IDENT|IDENTNL(N).          { SD = [TQNodeMethodArgumentDef nodeWithName:[(TQToken *)N value] selectorPart:[(TQToken *)S value]];}
oSelPart(SD) ::= kSelPart(T).                          { SD = T; [SD setDefaultArgument:[TQNodeNil node]];                            }
oSelPart(SD) ::= kSelPart(T) ASSIGN msgArg(E).         { SD = T; [SD setDefaultArgument:E];                                           }

onloadMessages(MS) ::= .                               { MS = [OFMutableArray array];                                                 }
onloadMessages(MS) ::= onloadMessages(O) onloadMessage(M). { MS = O; [(OFMutableArray *)MS addObject:M];                                               }
onloadMessage(M) ::= olMsgBeg(B) selPartNl(SP).        { [(OFMutableArray *)B addObject:SP]; M = [TQNodeMessage nodeWithReceiver:nil arguments:B];      }
olMsgBeg(M) ::= .                                      { M = [OFMutableArray array];                                                  }
olMsgBeg(M) ::= olMsgBeg(T) selPartNoNl(SP).           { M = T; [(OFMutableArray *)M addObject:SP];                                                     }

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
simpleAssign(A) ::= assignableNoNl(L) ASSIGN noAsgnExpr(R). { A = [TQNodeAssignOperator nodeWithTypeToken:ASSIGN left:[OFMutableArray arrayWithObject:L] right:[OFMutableArray arrayWithObject:R]];   }

assignNoNl(E) ::= assignLhs(A)
                  ASSIGN|ASSIGNADD|ASSIGNSUB|ASSIGNMUL|ASSIGNDIV|ASSIGNOR(OP)
                  assignRhsNoNl(B).                     { E = [TQNodeAssignOperator nodeWithTypeToken:[OP id] left:A right:B];        }

assignNl(E) ::= assignLhs(A)
                  ASSIGN|ASSIGNADD|ASSIGNSUB|ASSIGNMUL|ASSIGNDIV|ASSIGNOR(OP)
                  assignRhsNl(B).                       { E = [TQNodeAssignOperator nodeWithTypeToken:[OP id] left:A right:B];        }

assignLhs(L) ::= assignable(A).                         { L = [OFMutableArray arrayWithObject:A];                                     }
assignLhs(L) ::= assignLhs(O) COMMA assignable(E).      { L = O; [(OFMutableArray *)L addObject:E];                                   }

assignRhsNoNl(R) ::= assignRhsNoNl(O) COMMA rhsValNoNl(E). { R = O; [(OFMutableArray *)R addObject:E];                                }
assignRhsNoNl(R) ::= rhsValNoNl(V).                     { R = [OFMutableArray arrayWithObject:V];                                     }
assignRhsNl(R)   ::= assignRhsNoNl(O) COMMA rhsValNl(E).{ R = O; [(OFMutableArray *)R addObject:E];                                   }
assignRhsNl(R)   ::= rhsValNl(E).                       { R = [OFMutableArray arrayWithObject:E];                                     }

rhsValNoNl(V) ::= noAsgnExprNoNl(E).                    { V = E;                                                                      }
rhsValNl(V)   ::= noAsgnExprNl(E).                      { V = E;                                                                      }


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

literalNoNl(L) ::= NUMBER(T).                           { L = [TQNodeNumber nodeWithDouble:[[(TQToken *)T value] doubleValue]];       }
literalNoNl(L) ::= stringNoNl(S).                       { L = S;                                                                      }
literalNoNl(L) ::= arrayNoNl(A).                        { L = A;                                                                      }
literalNoNl(L) ::= dictNoNl(D).                         { L = D;                                                                      }
literalNoNl(L) ::= regexNoNl(D).                        { L = D;                                                                      }

literalNl(L)   ::= NUMBERNL(T).                         { L = [TQNodeNumber nodeWithDouble:[[(TQToken *)T value] doubleValue]];       }
literalNl(L)   ::= stringNl(S).                         { L = S;                                                                      }
literalNl(L)   ::= arrayNl(A).                          { L = A;                                                                      }
literalNl(L)   ::= dictNl(D).                           { L = D;                                                                      }
literalNl(L)   ::= regexNl(D).                          { L = D;                                                                      }


// Arrays
arrayNoNl(A) ::= LBRACKET RBRACKET.                     { A = [TQNodeArray node];                                                     }
arrayNoNl(A) ::= LBRACKET aryEls(EL) RBRACKET.          { A = [TQNodeArray node]; [A setItems:EL];                                    }
arrayNl(A)   ::= LBRACKET RBRACKETNL.                   { A = [TQNodeArray node];                                                     }
arrayNl(A)   ::= LBRACKET aryEls(EL) RBRACKETNL.        { A = [TQNodeArray node]; [A setItems:EL];                                    }

aryEls(EL)   ::= aryEls(O) COMMA noAsgnExpr(E).         { EL = O; [(OFMutableArray *)EL addObject:E];                                 }
aryEls(EL)   ::= noAsgnExpr(E).                         { EL = [OFMutableArray arrayWithObject:E];                                    }


// Dictionaries
dictNoNl(D) ::= LBRACE RBRACE.                          { D = [TQNodeDictionary node];                                                }
dictNoNl(D) ::= LBRACE dictEls(EL) RBRACE.              { D = [TQNodeDictionary node]; [D setItems:EL];                               }
dictNl(D)   ::= LBRACE RBRACENL.                        { D = [TQNodeDictionary node];                                                }
dictNl(D)   ::= LBRACE dictEls(EL) RBRACENL.            { D = [TQNodeDictionary node]; [D setItems:EL];                               }

dictEls(ELS) ::= dictEls(O) COMMA  dictEl(EL).          { ELS = O; for(id k in EL) [ELS OF_setObject:[EL objectForKey:k] forKey:k copyKey:NO ];      }
dictEls(ELS) ::= dictEl(EL).                            { ELS = EL;                                                                   }
dictEl(EL)  ::= noAsgnExpr(K) DICTSEP noAsgnExpr(V).    { EL = [OFMutableDictionary_hashtable dictionary]; [EL OF_setObject:V forKey:K copyKey:NO];           }

// Strings
stringNoNl(S) ::= CONSTSTR(V).                          { S = [TQNodeConstString nodeWithString:[(TQToken *)V value]];        }
stringNoNl(S) ::= STR(V).                               { S = [TQNodeString nodeWithString:[(TQToken *)V value]];             }
stringNoNl(S) ::= LSTR(L) inStr(M) RSTR(R).             { S = [TQNodeString nodeWithLeft:[(TQToken *)L value] embeds:M right:[(TQToken *)R value]];         }

stringNl(S)   ::= CONSTSTRNL(V).                        { S = [TQNodeConstString nodeWithString:(OFMutableString *)[(TQToken *)V value]];        }
stringNl(S)   ::= STRNL(V).                             { S = [TQNodeString nodeWithString:(OFMutableString *)[(TQToken *)V value]];             }
stringNl(S)   ::= LSTR(L) inStr(M) RSTRNL(R).           { S = [TQNodeString nodeWithLeft:[(TQToken *)L value] embeds:M right:[(TQToken *)R value]];         }

inStr(M) ::= inStr(O) MSTR(S) expr(E).                  { M = O; [(OFMutableArray *)M addObject:[(TQToken *)S value]]; [(OFMutableArray *)M addObject:E]; }
inStr(M) ::= expr(E).                                   { M = [OFMutableArray arrayWithObject:E];                                     }

// Regular expressions
regexNoNl(R) ::= REGEX(T).                             { R = [TQNodeRegex nodeWithPattern:[(TQToken *)T value]];                                }
regexNl(R)   ::= REGEXNL(T).                           { R = [TQNodeRegex nodeWithPattern:[(TQToken *)T value]];                                }

//
// Variables, Identifiers & Built-in Constants
//

//identifier(I)   ::= IDENT(T).                           { I = [T value];                                                              }
//identifier(I)   ::= IDENTNL(T).                         { I = [T value];                                                              }

constant(C)     ::= constantNoNl(T).                    { C = T;                                                                      }
constant(C)     ::= constantNl(T).                      { C = T;                                                                      }
constantNoNl(C) ::= CONST(T).                           { C = [TQNodeConstant nodeWithString:[(TQToken *)T value]];           }
constantNl(C)   ::= CONSTNL(T).                         { C = [TQNodeConstant nodeWithString:[(TQToken *)T value]];           }

variableNoNl(V) ::= IDENT(T).                           { V = [TQNodeVariable nodeWithName:[(TQToken *)T value]];                                }
variableNoNl(V) ::= SELF.                               { V = [TQNodeSelf node];                                                      }
variableNoNl(V) ::= SUPER.                              { V = [TQNodeSuper node];                                                     }
variableNoNl(V) ::= VALID.                              { V = [TQNodeValid node];                                                     }
variableNoNl(V) ::= YESTOK.                             { V = [TQNodeValid node];                                                     }
variableNoNl(V) ::= NOTOK.                              { V = [TQNodeNil node];                                                       }
variableNoNl(V) ::= NIL.                                { V = [TQNodeNil node];                                                       }
variableNoNl(V) ::= NOTHING.                            { V = [TQNodeNothing node];                                                   }
variableNoNl(V) ::= vaargNoNl(T).                       { V = T;                                                                      }

variableNl(V)   ::= IDENTNL(T).                         { V = [TQNodeVariable nodeWithName:[(TQToken *)T value]];                                }
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
propertyNoNl(P) ::= accessableNoNl(R) HASH IDENT(I).    { P = [TQNodeMemberAccess nodeWithReceiver:R property:[(TQToken *)I value]];             }
propertyNl(P)   ::= accessableNoNl(R) HASH IDENTNL(I).  { P = [TQNodeMemberAccess nodeWithReceiver:R property:[(TQToken *)I value]];             }
propertyNoNl(P) ::=                   HASH IDENT(I).    { P = [TQNodeMemberAccess nodeWithReceiver:[TQNodeSelf node] property:[(TQToken *)I value]]; }
propertyNl(P)   ::=                   HASH IDENTNL(I).  { P = [TQNodeMemberAccess nodeWithReceiver:[TQNodeSelf node] property:[(TQToken *)I value]]; }

// Misc
backtick        ::= BACKTICK|BACKTICKNL.

//
// Error Handling  --------------------------------------------------------------------------------------------------------------------
//

%syntax_error {
    TQAssert(NO, @"Syntax error near '%@' on line %d", [(TQToken *)TOKEN value], [(TQToken *)TOKEN line]);
}


// ------------------------------------------------------------------------------------------------------------------------------------

%include {
#import <Tranquil/CodeGen/CodeGen.h>
#import <Tranquil/Shared/TQDebug.h>
#import <Tranquil/Runtime/OFString+TQAdditions.h>

#define CONDKLS(T) ([T id] == IF    ? [TQNodeIfBlock class]    : [TQNodeUnlessBlock class])
#define LOOPKLS(T) ([T id] == WHILE ? [TQNodeWhileBlock class] : [TQNodeUntilBlock class])

// Private class from ObjFW
@interface OFMutableDictionary_hashtable : OFMutableDictionary
- (void)OF_setObject:(id)object forKey:(id)key copyKey:(BOOL)copyKey;
@end

// TQNode* methods to keep grammar actions to a single line

@interface TQNodeAssignOperator (TQParserAdditions)
+ (TQNodeAssignOperator *)nodeWithTypeToken:(int)token left:(OFMutableArray *)left right:(OFMutableArray *)right;
@end
@implementation TQNodeAssignOperator (TQParserAdditions)
+ (TQNodeAssignOperator *)nodeWithTypeToken:(int)token left:(OFMutableArray *)left right:(OFMutableArray *)right
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
+ (TQNodeBlock *)nodeWithArguments:(OFMutableArray *)args statement:(TQNode *)stmt;
+ (TQNodeBlock *)nodeWithArguments:(OFMutableArray *)args statements:(OFMutableArray *)statements;
@end
@implementation TQNodeBlock (TQParserAdditions)
+ (TQNodeBlock *)nodeWithArguments:(OFMutableArray *)args statement:(TQNode *)stmt;
{
    return [self nodeWithArguments:args statements:[OFMutableArray arrayWithObject:stmt]];
}
+ (TQNodeBlock *)nodeWithArguments:(OFMutableArray *)args statements:(OFMutableArray *)statements
{
    TQNodeBlock *ret = [TQNodeBlock node];

    for(TQNodeArgumentDef *arg in args) {
        if([[arg name] isEqual:@"..."]) {
            [ret setIsVariadic:YES];
            TQAssert(![arg defaultArgument], @"Syntax Error: '...' can't have a default value");
            size_t idx = [args indexOfObject:arg];
            TQAssert(idx == ([args count] - 1), @"Syntax Error: No arguments can come after '...'");
        } else
            [ret addArgument:arg error:nil];
    }
    [ret setStatements:statements];

    return ret;
}
@end

@interface TQNodeMessage (TQParserAdditions)
+ (TQNodeMessage *)unaryMessageWithReceiver:(TQNode *)rcvr selector:(OFString *)sel;
+ (TQNodeMessage *)nodeWithReceiver:(TQNode *)rcvr arguments:(OFMutableArray *)args;
@end
@implementation TQNodeMessage (TQParserAdditions)
+ (TQNodeMessage *)nodeWithReceiver:(TQNode *)rcvr arguments:(OFMutableArray *)args
{
    TQNodeMessage *ret = [TQNodeMessage nodeWithReceiver:rcvr];
    ret.arguments = args;
    return ret;
}
+ (TQNodeMessage *)unaryMessageWithReceiver:(TQNode *)rcvr selector:(OFString *)sel
{
    TQNodeMessage *ret = [TQNodeMessage nodeWithReceiver:rcvr];
    [ret.arguments addObject:[TQNodeArgument nodeWithPassedNode:nil selectorPart:sel]];
    return ret;
}
@end

@interface TQNodeString (TQParserAdditions)
+ (TQNodeString *)nodeWithLeft:(OFString *)left embeds:(OFMutableArray *)embeds right:(OFString *)right;
@end
@implementation TQNodeString (TQParserAdditions)
+ (TQNodeString *)nodeWithLeft:(OFMutableString *)left embeds:(OFMutableArray *)embeds right:(OFMutableString *)right;
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
