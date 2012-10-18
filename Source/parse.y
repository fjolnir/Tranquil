program ::= statements.

statements ::= statements statement.
statements ::= .

statement ::= unaryMsgNl(E).                      { NSLog(@"e: %@", E);                                                         }
statement ::= kwdMsg(E).                          { NSLog(@"e: %@", E);                                                         }

expr(E) ::= parenExpr(PE).                        { E = PE;                                                                     }
expr(E) ::= variable(V).                          { E = V;                                                                      }
expr(E) ::= literal(L).                           { E = L;                                                                      }
expr(E) ::= unaryMsg(M).                          { E = M;                                                                      }
expr(E) ::= kwdMsg(M).                            { E = M;                                                                      }

parenExpr(PE) ::= LPAREN expr(E) RPAREN.          { PE = E;                                                                     }

// Operators
%right ASSIGN.
%left  AND OR.
%left  EQUAL NEQUAL GREATER LESSER GEQUAL LEQUAL.
%left  PLUS MINUS.
%left  ASTERISK FSLASH PERCENT.
%left  INCR DECR.
%right CARET.

expr(E) ::= expr(A) ASSIGN expr(B).               { E = [TQNodeOperator nodeWithType:kTQOperatorAssign left:A right:B];         }

// Unary message
unaryMsgNl(M) ::= msgRcvr(R) unarySelNl(S).       { // Unary msg at the end of a line
    M = [TQNodeMessage nodeWithReceiver:R];
    [[(TQNodeMessage *)M arguments] addObject:[TQNodeArgument nodeWithPassedNode:nil selectorPart:S]];
}
unarySelNl(U) ::= IDENTNL(T).                     { U = T;                                                                      }
unarySelNl(U) ::= CONSTNL(T).                     { U = T;                                                                      }

unaryMsg(M) ::= msgRcvr(R) unarySel(S).           {
    M = [TQNodeMessage nodeWithReceiver:R];
    [[(TQNodeMessage *)M arguments] addObject:[TQNodeArgument nodeWithPassedNode:nil selectorPart:S]];
}
unarySel(U)  ::= IDENT(T).                        { U = T;                                                                      }
unarySel(U)  ::= CONST(T).                        { U = T;                                                                      }

// Keyword message
kwdMsg(M) ::= msgRcvr(R) kwdSel(A).               {
    M = [TQNodeMessage nodeWithReceiver:R];
    [M setArguments:A];
}
selPart(SP) ::= SELPART(T) msgArg(A).             { SP = [TQNodeArgument nodeWithPassedNode:A selectorPart:T];                  }
kwdSel(S)   ::= selPart(SP).                      { S  = [NSMutableArray arrayWithObject:SP];                                   }
kwdSel(S)   ::= kwdSel(SS) selPart(SP).           { S  = SS; [S addObject:SP];                                                  }

msgRcvr(R) ::= literal(L).                        { R = L;                                                                      }
msgRcvr(R) ::= variable(V).                       { R = V;                                                                      }
msgRcvr(R) ::= parenExpr(E).                      { R = E;                                                                      }
msgRcvr(R) ::= unaryMsg(E).                       { R = E;                                                                      }

//msgArg(A)  ::= msgRcvr(UR).                     { A = UR; }
//msgArg(A)  ::= unaryMsg(UR).                    { A = UR; }
msgArg(A)  ::= unaryMsgNl(UR).                    { A = UR; }

// Logic
expr(O)  ::= expr(A) AND expr(B).                 { O = [TQNodeOperator nodeWithType:kTQOperatorAnd left:A right:B];            }
expr(O)  ::= expr(A) OR  expr(B).                 { O = [TQNodeOperator nodeWithType:kTQOperatorOr  left:A right:B];            }

// Arithmetic
expr(O)  ::= expr(A) PLUS     expr(B).            { O = [TQNodeOperator nodeWithType:kTQOperatorAdd        left:A   right:B];   }
expr(O)  ::= expr(A) MINUS    expr(B).            { O = [TQNodeOperator nodeWithType:kTQOperatorSubtract   left:A   right:B];   }
expr(O)  ::= expr(A) ASTERISK expr(B).            { O = [TQNodeOperator nodeWithType:kTQOperatorMultiply   left:A   right:B];   }
expr(O)  ::= expr(A) FSLASH   expr(B).            { O = [TQNodeOperator nodeWithType:kTQOperatorDivide     left:A   right:B];   }
expr(O)  ::= expr(A) PERCENT  expr(B).            { O = [TQNodeOperator nodeWithType:kTQOperatorModulo     left:A   right:B];   }
expr(O)  ::= expr(A) CARET    expr(B).            { O = [TQNodeOperator nodeWithType:kTQOperatorExponent   left:A   right:B];   }
// Unary operators
expr(O)  ::= MINUS expr(A).                       { O = [TQNodeOperator nodeWithType:kTQOperatorUnaryMinus left:nil right:A];   }
expr(O)  ::= INCR  expr(A).                       { O = [TQNodeOperator nodeWithType:kTQOperatorIncrement  left:nil right:A];   }
expr(O)  ::= expr(A) INCR.                        { O = [TQNodeOperator nodeWithType:kTQOperatorIncrement  left:A   right:nil]; }
expr(O)  ::= DECR expr(A).                        { O = [TQNodeOperator nodeWithType:kTQOperatorDecrement  left:nil right:A];   }
expr(O)  ::= expr(A) DECR.                        { O = [TQNodeOperator nodeWithType:kTQOperatorDecrement  left:A   right:nil]; }

// Comparisons
expr(O)  ::= expr(A) EQUAL   expr(B).             { O = [TQNodeOperator nodeWithType:kTQOperatorEqual          left:A right:B]; }
expr(O)  ::= expr(A) NEQUAL  expr(B).             { O = [TQNodeOperator nodeWithType:kTQOperatorInequal        left:A right:B]; }
expr(O)  ::= expr(A) GREATER expr(B).             { O = [TQNodeOperator nodeWithType:kTQOperatorGreater        left:A right:B]; }
expr(O)  ::= expr(A) LESSER  expr(B).             { O = [TQNodeOperator nodeWithType:kTQOperatorLesser         left:A right:B]; }
expr(O)  ::= expr(A) GEQUAL  expr(B).             { O = [TQNodeOperator nodeWithType:kTQOperatorGreaterOrEqual left:A right:B]; }
expr(O)  ::= expr(A) LEQUAL  expr(B).             { O = [TQNodeOperator nodeWithType:kTQOperatorLesserOrEqual  left:A right:B]; }

// Arrays
array(A)   ::= LBRACKET RBRACKET.                 { A = [TQNodeArray node];                                                     }
array(A)   ::= LBRACKET aryEls(EL) RBRACKET.      { A = [TQNodeArray node]; [A setItems:EL];                                    }
aryEls(EL) ::= aryEls(O) COMMA expr(E).           { EL = O; [EL addObject:E];                                                   }
aryEls(EL) ::= expr(E).                           { EL = [NSMutableArray arrayWithObject:E];                                    }

// Dictionaries
dict(D)     ::= LBRACE RBRACE.                    { D = [TQNodeDictionary node];                                                }
dict(D)     ::= LBRACE dictEls(EL) RBRACE.        { D = [TQNodeDictionary node]; [D setItems:EL];                               }
dictEls(EL) ::= dictEls(O)
                COMMA expr(K) DICTSEP expr(V).    { EL = O; [EL setObject:V forKey:K];                                          }
dictEls(EL) ::= expr(K) DICTSEP expr(V).          { EL = [[NSMapTable new] autorelease];
                                                    [EL setObject:V forKey:K];                                                  }

// Basics
literal(L)  ::= number(N).                        { L = N;                                                                      }
literal(L)  ::= string(S).                        { L = S;                                                                      }
literal(L)  ::= array(A).                         { L = A;                                                                      }
literal(L)  ::= dict(D).                          { L = D;                                                                      }

number(N)   ::= NUMBER(T).                        { N = [TQNodeNumber nodeWithDouble:[T doubleValue]];                          }

string(S)   ::= STR(V).                           { S = [TQNodeString nodeWithString:V];                                        }
string(S)   ::= LSTR(L) inStr(M) RSTR(R).         {
    S = [TQNodeString nodeWithString:L];
    for(int i = 0; i < [M count]; ++i) {
        if(i == 0 || i % 2 == 0) {
            [[(TQNodeString *)S value] appendString:@"%@"];
            [[(TQNodeString *)S embeddedValues] addObject:[M objectAtIndex:i]];
        } else
            [[(TQNodeString *)S value] appendString:[M objectAtIndex:i]];
    }
    [[(TQNodeString *)S value] appendString:R];
}
inStr(M) ::= inStr(OLD) MSTR(S) expr(E).          { M = OLD; [M addObject:S]; [M addObject:E];                                  }
inStr(M) ::= expr(E).                             { M = [NSMutableArray arrayWithObject:E];                                     }

// This is a bit messy, but it's a lot less messy than actually including an NL token.
variableNoNl(V) ::= IDENT(T).                     { V = [TQNodeVariable nodeWithName:T];                                        }
variableNoNl(V) ::= SELF.                         { V = [TQNodeSelf node];                                                      }
variableNoNl(V) ::= SUPER.                        { V = [TQNodeSuper node];                                                     }
variableNoNl(V) ::= VALID.                        { V = [TQNodeValid node];                                                     }
variableNoNl(V) ::= YES.                          { V = [TQNodeValid node];                                                     }
variableNoNl(V) ::= NO.                           { V = [TQNodeNil node];                                                       }
variableNoNl(V) ::= NIL.                          { V = [TQNodeNil node];                                                       }
variableNoNl(V) ::= NOTHING.                      { V = [TQNodeNothing node];                                                   }
variableNoNl(V) ::= vaargNoNl(T).                 { V = T;                                                                      }
vaargNoNl(V)    ::= VAARG.                        { V = [TQNodeVariable nodeWithName:@"..."];                                   }
variableNl(V)   ::= IDENTNL(T).                   { V = [TQNodeVariable nodeWithName:T];                                        }
variableNl(V)   ::= SELFNL.                       { V = [TQNodeSelf node];                                                      }
variableNl(V)   ::= SUPERNL.                      { V = [TQNodeSuper node];                                                     }
variableNl(V)   ::= VALIDNL.                      { V = [TQNodeValid node];                                                     }
variableNl(V)   ::= YESNL.                        { V = [TQNodeValid node];                                                     }
variableNl(V)   ::= NONL.                         { V = [TQNodeNil node];                                                       }
variableNl(V)   ::= NILNL.                        { V = [TQNodeNil node];                                                       }
variableNl(V)   ::= NOTHINGNL.                    { V = [TQNodeNothing node];                                                   }
variableNl(V)   ::= vaargNl(T).                   { V = T;                                                                      }
vaargNl(V)      ::= VAARGNL.                      { V = [TQNodeVariable nodeWithName:@"..."];                                   }

variable(V)     ::= variableNoNl(T).              { V = T;                                                                      }
variable(V)     ::= variableNl(T).                { V = T;                                                                      }

// -------------------------------------------------------------------------------------

%include { #import <Tranquil/CodeGen/CodeGen.h> }
%token_type id
%extra_argument { TQParserState *state }

%parse_failure {
    fprintf(stderr, "Giving up.  Parser is hopelessly lost...\n");
}
