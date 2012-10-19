// Lemon grammar for tranquil

// (Let me apologize in advance for the *(No)Nl variants. This was the simplest way I could
//  think of to implement newline separated statements in a LALR(1) grammar; Including an NL
//  token would have been worse)

%token_type id
%extra_argument { TQParserState *state }

program ::= statements(SS). { NSLog(@"> %@", SS); }

//
// Statements -------------------------------------------------------------------------------------------------------------------------
//

statements(SS) ::= statements(O) statement(S).          { SS = O; [SS addObject:S];                                                   }
statements(SS) ::= statement(S).                        { SS = [NSMutableArray arrayWithObject:S];                                    }

statement(S) ::= exprNl(E).                             { S = E;                                                                      }


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
noAsgnExprNoNl(E) ::= simpleExprNoNl(T).                { E = T;                                                                      }
noAsgnExprNl(E) ::= kwdMsgNl(M).                        { E = M;                                                                      }
noAsgnExprNl(E) ::= opNl(O).                            { E = O;                                                                      }
noAsgnExprNl(E) ::= simpleExprNl(T).                    { E = T;                                                                      }

parenExprNoNl(PE) ::= LPAREN expr(E) RPAREN.            { PE = E;                                                                     }
parenExprNl(PE)   ::= LPAREN expr(E) RPARENNL.          { PE = E;                                                                     }

simpleExprNoNl(E) ::= parenExprNoNl(PE).                { E = PE;                                                                     }
simpleExprNoNl(E) ::= literalNoNl(L).                   { E = L;                                                                      }
simpleExprNoNl(E) ::= unaryMsgNoNl(M).                  { E = M;                                                                      }
simpleExprNoNl(E) ::= assignableNoNl(L).                { E = L;                                                                      }
simpleExprNoNl(E) ::= unaryOpNoNl(M).                   { E = M;                                                                      }
simpleExprNl(E) ::= parenExprNl(PE).                    { E = PE;                                                                     }
simpleExprNl(E) ::= literalNl(L).                       { E = L;                                                                      }
simpleExprNl(E) ::= unaryMsgNl(M).                      { E = M;                                                                      }
simpleExprNl(E) ::= assignableNl(L).                    { E = L;                                                                      }
simpleExprNl(E) ::= unaryOpNl(M).                       { E = M;                                                                      }


//
// Messages ---------------------------------------------------------------------------------------------------------------------------
//

// Unary messages
unaryMsgNoNl(M) ::= msgRcvr(R) unarySelNoNl(S). [INCR]  { M = [TQNodeMessage unaryMessageWithReceiver:R selector:S];                  }
unarySelNoNl(U) ::= IDENT(T).                           { U = T;                                                                      }
unarySelNoNl(U) ::= CONST(T).                           { U = T;                                                                      }

unaryMsgNl(M)   ::= msgRcvr(R) unarySelNl(S).           { M = [TQNodeMessage unaryMessageWithReceiver:R selector:S];                  }
unarySelNl(U)   ::= IDENTNL(T).                         { U = T;                                                                      }
unarySelNl(U)   ::= CONSTNL(T).                         { U = T;                                                                      }


// Keyword messages
kwdMsgNoNl(M) ::= msgRcvr(R) selPartsNoNl(SP).          { M = [TQNodeMessage nodeWithReceiver:R arguments:SP];                        }
kwdMsgNl(M)   ::= msgRcvr(R) selPartsNl(SP).            { M = [TQNodeMessage nodeWithReceiver:R arguments:SP];                        }

selParts(ARR)     ::= .                                 { ARR = [NSMutableArray array];                                               }
selParts(ARR)     ::= selParts(T) selPart(SP).          { ARR = T; [ARR addObject:SP];                                                }
selPartsNl(ARR)   ::= selParts(T) selPartNl(SP).        { ARR = T; [ARR addObject:SP];                                                }
selPartsNoNl(ARR) ::= selParts(T) selPartNoNl(SP).      { ARR = T; [ARR addObject:SP];                                                }

selPart(SP)     ::= SELPART(T) msgArg(A).               { SP = [TQNodeArgument nodeWithPassedNode:A selectorPart:T];                  }
selPartNoNl(SP) ::= SELPART(T) msgArgNoNl(A).           { SP = [TQNodeArgument nodeWithPassedNode:A selectorPart:T];                  }
selPartNl(SP)   ::= SELPART(T) msgArgNl(A).             { SP = [TQNodeArgument nodeWithPassedNode:A selectorPart:T];                  }

msgRcvr(R) ::= simpleExprNoNl(L).                       { R = L;                                                                      }

msgArg(A) ::= msgArgNoNl(T).                            { A = T;                                                                      }
msgArg(A) ::= msgArgNl(T).                              { A = T;                                                                      }

msgArgNoNl(A) ::= simpleExprNoNl(E). { A = E; }
msgArgNoNl(A) ::= opNoNl(E). { A = E; }
msgArgNl(A) ::= simpleExprNl(E). { A = E; }
msgArgNl(A) ::= opNl(E). { A = E; }


//
// Blocks Definitions -----------------------------------------------------------------------------------------------------------------
//

simpleExprNl(E)   ::= blockNl(B).                      { E = B;                                                                       }

blockNl(B) ::= LBRACE statements(S) RBRACENL.          { B = [TQNodeBlock node]; [B setStatements:S];                                 }
blockNl(B) ::= LBRACE identifier(I) blockArgs(A) PIPE statements(S) RBRACENL. {
    B = [TQNodeBlock nodeWithFirstArg:I defaultVal:nil arguments:A statements:S];
}
blockNl(B) ::= LBRACEDEFARG(I) expr(D) blockArgs(A) PIPE statements(S) RBRACENL. {
    B = [TQNodeBlock nodeWithFirstArg:I defaultVal:D arguments:A statements:S];
}

blockNl(B) ::= BACKTICK expr(E) BACKTICKNL. { B = [TQNodeBlock node]; [[B statements] addObject:[TQNodeReturn nodeWithValue:E]];      }
blockNl(B) ::= BACKTICK identifier(I) blockArgs(A) PIPE expr(E) BACKTICKNL. {
    B = [TQNodeBlock nodeWithFirstArg:I defaultVal:nil arguments:A statement:[TQNodeReturn nodeWithValue:E]];
}
blockNl(B) ::= BACKTICKDEFARG(I) expr(D) blockArgs(A) PIPE expr(E) BACKTICKNL. {
    B = [TQNodeBlock nodeWithFirstArg:I defaultVal:D arguments:A statement:[TQNodeReturn nodeWithValue:E]];
}

blockArgs(L) ::= .                                     { L = [NSMutableArray array];                                                  }
blockArgs(L) ::= blockArgs(O) COMMA blockArg(E).       { L = O; [L addObject:E];                                                      }

blockArg(A) ::= identifier(N).                         { A = [TQNodeArgumentDef nodeWithName:N];                                      }
blockArg(A) ::= identifier(N) ASSIGN noAsgnExpr(E).    { A = [TQNodeArgumentDef nodeWithName:N]; [A setDefaultArgument:E];            }

//
// Block Calls ------------------------------------------------------------------------------------------------------------------------
//

simpleExprNoNl(E) ::= blockCallNoNl(C).                 { E = C;                                                                      }
simpleExprNl(E)   ::= blockCallNl(C).                   { E = C;                                                                      }

blockCallNoNl(C)  ::= accessableNoNl(A) LPAREN callArgs(ARGS) RPAREN. { C = [TQNodeCall nodeWithCallee:A]; [C setArguments:ARGS];     }
blockCallNl(C)  ::= accessableNoNl(A) LPAREN callArgs(ARGS) RPARENNL. { C = [TQNodeCall nodeWithCallee:A]; [C setArguments:ARGS];     }

callArgs       ::= .
callArgs(L)    ::= expr(E).                             { L = [NSMutableArray arrayWithObject:E];                                     }
callArgs(L)    ::= callArgs(O) COMMA expr(E).           { L = O; [L addObject:E];                                                     }


//
// Operators --------------------------------------------------------------------------------------------------------------------------
//

// Precedence
%right ASSIGN.
%left  AND OR.
%left  EQUAL INEQUAL GREATER LESSER GEQUAL LEQUAL.
%left  PLUS MINUS.
%left  ASTERISK FSLASH PERCENT.
%left  INCR DECR LUNARY .
%right CARET RUNARY.

// bOp: binary operator (arithmetic & logic; not comparisons or assignments)
opNoNl(O) ::= bOpNoNl(UO).                              { O = UO;                                                                     }
opNl(O)   ::= bOpNl(UO).                                { O = UO;                                                                     }

opLhs(R) ::= opLhsNoNl(T). { R = T; }
opLhs(R) ::= opLhsNl(T). { R = T; }

opLhsNoNl(R) ::= simpleExprNoNl(E).                     { R = E;                                                                      }
opLhsNoNl(R) ::= bOpNoNl(E).                            { R = E;                                                                      }
opLhsNl(R)   ::= simpleExprNl(E).                       { R = E;                                                                      }
opLhsNl(R)   ::= bOpNl(E).                              { R = E;                                                                      }

//Assignment
assignNoNl(E) ::= assignable(A) ASSIGN exprNoNl(B).     { E = [TQNodeOperator nodeWithType:kTQOperatorAssign left:A right:B];         }
assignNl(E)   ::= assignable(A) ASSIGN exprNl(B).       { E = [TQNodeOperator nodeWithType:kTQOperatorAssign left:A right:B];         }


// Logic
opNoNl(O)  ::= opLhs(A) AND simpleExprNoNl(B).          { O = [TQNodeOperator nodeWithType:kTQOperatorAnd left:A right:B];            }
opNoNl(O)  ::= opLhs(A) OR  simpleExprNoNl(B).          { O = [TQNodeOperator nodeWithType:kTQOperatorOr  left:A right:B];            }
opNl(O)    ::= opLhs(A) AND simpleExprNl(B).            { O = [TQNodeOperator nodeWithType:kTQOperatorAnd left:A right:B];            }
opNl(O)    ::= opLhs(A) OR  simpleExprNl(B).            { O = [TQNodeOperator nodeWithType:kTQOperatorOr  left:A right:B];            }

// Arithmetic
bOpNoNl(O) ::= opLhsNoNl(A) PLUS     simpleExprNoNl(B). { O = [TQNodeOperator nodeWithType:kTQOperatorAdd        left:A   right:B];   }
bOpNoNl(O) ::= opLhsNoNl(A) MINUS    simpleExprNoNl(B). { O = [TQNodeOperator nodeWithType:kTQOperatorSubtract   left:A   right:B];   }
bOpNoNl(O) ::= opLhsNoNl(A) ASTERISK simpleExprNoNl(B). { O = [TQNodeOperator nodeWithType:kTQOperatorMultiply   left:A   right:B];   }
bOpNoNl(O) ::= opLhsNoNl(A) FSLASH   simpleExprNoNl(B). { O = [TQNodeOperator nodeWithType:kTQOperatorDivide     left:A   right:B];   }
bOpNoNl(O) ::= opLhsNoNl(A) PERCENT  simpleExprNoNl(B). { O = [TQNodeOperator nodeWithType:kTQOperatorModulo     left:A   right:B];   }
bOpNoNl(O) ::= opLhsNoNl(A) CARET    simpleExprNoNl(B). { O = [TQNodeOperator nodeWithType:kTQOperatorExponent   left:A   right:B];   }

bOpNl(O) ::= opLhsNoNl(A) PLUS     simpleExprNl(B).     { O = [TQNodeOperator nodeWithType:kTQOperatorAdd        left:A   right:B];   }
bOpNl(O) ::= opLhsNoNl(A) MINUS    simpleExprNl(B).     { O = [TQNodeOperator nodeWithType:kTQOperatorSubtract   left:A   right:B];   }
bOpNl(O) ::= opLhsNoNl(A) ASTERISK simpleExprNl(B).     { O = [TQNodeOperator nodeWithType:kTQOperatorMultiply   left:A   right:B];   }
bOpNl(O) ::= opLhsNoNl(A) FSLASH   simpleExprNl(B).     { O = [TQNodeOperator nodeWithType:kTQOperatorDivide     left:A   right:B];   }
bOpNl(O) ::= opLhsNoNl(A) PERCENT  simpleExprNl(B).     { O = [TQNodeOperator nodeWithType:kTQOperatorModulo     left:A   right:B];   }
bOpNl(O) ::= opLhsNoNl(A) CARET    simpleExprNl(B).     { O = [TQNodeOperator nodeWithType:kTQOperatorExponent   left:A   right:B];   }

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
opNoNl(O) ::= opLhs(A) EQUAL   compRhsNoNl(B).          { O = [TQNodeOperator nodeWithType:kTQOperatorEqual          left:A right:B]; }
opNoNl(O) ::= opLhs(A) INEQUAL compRhsNoNl(B).          { O = [TQNodeOperator nodeWithType:kTQOperatorInequal        left:A right:B]; }
opNoNl(O) ::= opLhs(A) GREATER compRhsNoNl(B).          { O = [TQNodeOperator nodeWithType:kTQOperatorGreater        left:A right:B]; }
opNoNl(O) ::= opLhs(A) LESSER  compRhsNoNl(B).          { O = [TQNodeOperator nodeWithType:kTQOperatorLesser         left:A right:B]; }
opNoNl(O) ::= opLhs(A) GEQUAL  compRhsNoNl(B).          { O = [TQNodeOperator nodeWithType:kTQOperatorGreaterOrEqual left:A right:B]; }
opNoNl(O) ::= opLhs(A) LEQUAL  compRhsNoNl(B).          { O = [TQNodeOperator nodeWithType:kTQOperatorLesserOrEqual  left:A right:B]; }

opNl(O) ::= opLhs(A) EQUAL   compRhsNl(B).              { O = [TQNodeOperator nodeWithType:kTQOperatorEqual          left:A right:B]; }
opNl(O) ::= opLhs(A) INEQUAL compRhsNl(B).              { O = [TQNodeOperator nodeWithType:kTQOperatorInequal        left:A right:B]; }
opNl(O) ::= opLhs(A) GREATER compRhsNl(B).              { O = [TQNodeOperator nodeWithType:kTQOperatorGreater        left:A right:B]; }
opNl(O) ::= opLhs(A) LESSER  compRhsNl(B).              { O = [TQNodeOperator nodeWithType:kTQOperatorLesser         left:A right:B]; }
opNl(O) ::= opLhs(A) GEQUAL  compRhsNl(B).              { O = [TQNodeOperator nodeWithType:kTQOperatorGreaterOrEqual left:A right:B]; }
opNl(O) ::= opLhs(A) LEQUAL  compRhsNl(B).              { O = [TQNodeOperator nodeWithType:kTQOperatorLesserOrEqual  left:A right:B]; }

compRhsNoNl(R) ::= simpleExprNoNl(B). { R = B; }
compRhsNoNl(R) ::= bOpNoNl(B). { R = B; }

compRhsNl(R) ::= simpleExprNl(B). { R = B; }
compRhsNl(R) ::= bOpNl(B). { R = B; }

//
// Literals ---------------------------------------------------------------------------------------------------------------------------
//

literalNoNl(L) ::= NUMBER(T).                           { L = [TQNodeNumber nodeWithDouble:[T doubleValue]];                          }
literalNoNl(L) ::= stringNoNl(S).                       { L = S;                                                                      }
literalNoNl(L) ::= arrayNoNl(A).                        { L = A;                                                                      }
literalNoNl(L) ::= dictNoNl(D).                         { L = D;                                                                      }

literalNl(L)   ::= NUMBERNL(T).                         { L = [TQNodeNumber nodeWithDouble:[T doubleValue]];                          }
literalNl(L)   ::= stringNl(S).                         { L = S;                                                                      }
literalNl(L)   ::= arrayNl(A).                          { L = A;                                                                      }
literalNl(L)   ::= dictNl(D).                           { L = D;                                                                      }


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

dictEls(ELS) ::= dictEls(O) COMMA  dictEl(EL).          { ELS = O; [ELS addEntriesFromDictionary:EL];                                 }
dictEls(ELS) ::= dictEl(EL).                            { ELS = EL;                                                                   }
dictEl(EL)  ::= noAsgnExpr(K) DICTSEP noAsgnExpr(V).    { EL = [NSMutableDictionary dictionaryWithObject:V forKey:K];                 }

// Strings
stringNoNl(S) ::= STR(V).                               { S = [TQNodeString nodeWithString:V];                                        }
stringNoNl(S) ::= LSTR(L) inStr(M) RSTR(R).             { S = [TQNodeString nodeWithLeft:L embeds:M right:R];                         }

stringNl(S)   ::= STRNL(V).                             { S = [TQNodeString nodeWithString:V];                                        }
stringNl(S)   ::= LSTR(L) inStr(M) RSTRNL(R).           { S = [TQNodeString nodeWithLeft:L embeds:M right:R];                         }

inStr(M) ::= inStr(OLD) MSTR(S) expr(E).                { M = OLD; [M addObject:S]; [M addObject:E];                                  }
inStr(M) ::= expr(E).                                   { M = [NSMutableArray arrayWithObject:E];                                     }


//
// Variables, Identifiers & Built-in Constants
//

identifier(I)   ::= IDENT(T).                           { I = T;                                                                      }
identifier(I)   ::= IDENTNL(T).                         { I = T;                                                                      }

variableNoNl(V) ::= IDENT(T).                           { V = [TQNodeVariable nodeWithName:T];                                        }
variableNoNl(V) ::= SELF.                               { V = [TQNodeSelf node];                                                      }
variableNoNl(V) ::= SUPER.                              { V = [TQNodeSuper node];                                                     }
variableNoNl(V) ::= VALID.                              { V = [TQNodeValid node];                                                     }
variableNoNl(V) ::= YES.                                { V = [TQNodeValid node];                                                     }
variableNoNl(V) ::= NO.                                 { V = [TQNodeNil node];                                                       }
variableNoNl(V) ::= NIL.                                { V = [TQNodeNil node];                                                       }
variableNoNl(V) ::= NOTHING.                            { V = [TQNodeNothing node];                                                   }
variableNoNl(V) ::= vaargNoNl(T).                       { V = T;                                                                      }
vaargNoNl(V)    ::= VAARG.                              { V = [TQNodeVariable nodeWithName:@"..."];                                   }

variableNl(V)   ::= IDENTNL(T).                         { V = [TQNodeVariable nodeWithName:T];                                        }
variableNl(V)   ::= SELFNL.                             { V = [TQNodeSelf node];                                                      }
variableNl(V)   ::= SUPERNL.                            { V = [TQNodeSuper node];                                                     }
variableNl(V)   ::= VALIDNL.                            { V = [TQNodeValid node];                                                     }
variableNl(V)   ::= YESNL.                              { V = [TQNodeValid node];                                                     }
variableNl(V)   ::= NONL.                               { V = [TQNodeNil node];                                                       }
variableNl(V)   ::= NILNL.                              { V = [TQNodeNil node];                                                       }
variableNl(V)   ::= NOTHINGNL.                          { V = [TQNodeNothing node];                                                   }
variableNl(V)   ::= vaargNl(T).                         { V = T;                                                                      }
vaargNl(V)      ::= VAARGNL.                            { V = [TQNodeVariable nodeWithName:@"..."];                                   }

// Accessables (Simple values; needs to be merged with simpleExpr when I resolve the conflicts that occur)
accessableNoNl(A) ::= variableNoNl(V).                  { A = V;                                                                      }
accessableNoNl(A) ::= literalNoNl(V).                   { A = V;                                                                      }
accessableNoNl(A) ::= parenExprNoNl(V).                 { A = V;                                                                      }
accessableNoNl(A) ::= TILDE accessableNoNl(V).          { A = [TQNodeWeak nodeWithValue:V];                                           }

accessableNl(A) ::= variableNl(V).                      { A = V;                                                                      }
accessableNl(A) ::= literalNl(V).                       { A = V;                                                                      }
accessableNl(A) ::= parenExprNl(V).                     { A = V;                                                                      }
accessableNl(A) ::= TILDE accessableNl(V).              { A = [TQNodeWeak nodeWithValue:V];                                           }

// Assignables
assignable(V)     ::= assignableNoNl(T).                { V = T;                                                                      }
assignable(V)     ::= assignableNl(T).                  { V = T;                                                                      }

assignableNoNl(V) ::= variableNoNl(T).                  { V = T;                                                                      }
assignableNoNl(V) ::= subscriptNoNL(T).                 { V = T;                                                                      }
assignableNoNl(V) ::= propertyNoNl(T).                  { V = T;                                                                      }
assignableNl(V)   ::= variableNl(T).                    { V = T;                                                                      }
assignableNl(V)   ::= subscriptNL(T).                   { V = T;                                                                      }
assignableNl(V)   ::= propertyNl(T).                    { V = T;                                                                      }

// Subscripts
subscriptNoNL(S) ::= accessableNoNl(L)
                     LBRACKET expr(E) RBRACKET.         { S = [TQNodeOperator nodeWithType:kTQOperatorSubscript left:L right:E];      }
subscriptNL(S)   ::= accessableNoNl(L)
                     LBRACKET expr(E) RBRACKETNL.       { S = [TQNodeOperator nodeWithType:kTQOperatorSubscript left:L right:E];      }

// Properties
propertyNoNl(P) ::= accessableNoNl(R) HASH IDENT(I).    { P = [TQNodeMemberAccess nodeWithReceiver:R property:I];                     }
propertyNl(P)   ::= accessableNoNl(R) HASH IDENTNL(I).  { P = [TQNodeMemberAccess nodeWithReceiver:R property:I];                     }
propertyNoNl(P) ::=                   HASH IDENT(I).    { P = [TQNodeMemberAccess nodeWithReceiver:[TQNodeSelf node] property:I];     }
propertyNl(P)   ::=                   HASH IDENTNL(I).  { P = [TQNodeMemberAccess nodeWithReceiver:[TQNodeSelf node] property:I];     }


//
// Error Handling  --------------------------------------------------------------------------------------------------------------------
//

%syntax_error {
    NSLog(@"SYNTAX ERROR '%@'", TOKEN);
    exit(1);
}
%parse_failure {
    fprintf(stderr, "Giving up.  Parser is hopelessly lost...\n");
}


// ------------------------------------------------------------------------------------------------------------------------------------

%include {
#import <Tranquil/CodeGen/CodeGen.h>

// TQNode* methods to keep grammar actions to a single line
@interface TQNodeBlock (TQParserAdditions)
+ (TQNodeBlock *)nodeWithFirstArg:(NSString *)argName defaultVal:(TQNode *)defVal arguments:(NSMutableArray *)args statement:(TQNode *)stmt;
+ (TQNodeBlock *)nodeWithFirstArg:(NSString *)argName defaultVal:(TQNode *)defVal arguments:(NSMutableArray *)args statements:(NSMutableArray *)statements;
@end
@implementation TQNodeBlock (TQParserAdditions)
+ (TQNodeBlock *)nodeWithFirstArg:(NSString *)argName defaultVal:(TQNode *)defVal arguments:(NSMutableArray *)args statement:(TQNode *)stmt
{
    return [self nodeWithFirstArg:argName defaultVal:defVal arguments:args statements:[NSMutableArray arrayWithObject:stmt]];
}
+ (TQNodeBlock *)nodeWithFirstArg:(NSString *)argName defaultVal:(TQNode *)defVal arguments:(NSMutableArray *)args statements:(NSMutableArray *)statements
{
    TQNodeBlock *ret = [TQNodeBlock node];

    TQNodeArgumentDef *firstArg = [TQNodeArgumentDef nodeWithName:argName];
    [firstArg setDefaultArgument:defVal];
    [args insertObject:firstArg atIndex:0];
    [ret setArguments:args];
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

