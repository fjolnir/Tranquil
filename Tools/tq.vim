" Vim syntax file
" Language:    Tranquil
" Maintainer:  Fjölnir Ásgeirsson <fjolnir@asgeirsson.is

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

let s:cpo_save = &cpo
set cpo&vim

" some keywords and standard methods
syn keyword tqKeyword if else unless while until import async wait whenFinished lock
syn keyword tqKeywordLiteral super self yes no nil

" Constants
"syn match tqConstant "[^a-z][A-Z][A-Za-z0-9_]*" contained

" Class definition
syn match tqClassDef "^#[A-Z][A-Za-z0-9_]*\s*(<\s*[A-Z][A-Za-z0-9_]*)?"

" Method definitions
syn match stInstMethod    "^\s*-\s*"
syn match stClassMethod   "^\s*+\s*"

" Selector colon
syn match tqMessageColon ":" 

syn match tqComment "\\.*"

syn region tqString start='"' skip='\\"' end='"' contains=tqInterpolation
syn region tqInterpolation matchgroup=tqInterpolated start="#{" end="}" contained contains=ALLBUT,tqBlockError

" Normal Regular Expression
"syn region tqRegexp matchgroup=tqRegexpDelimit start="/" skip="\\\\\|\\/" end="/[im]*" contains=tqInterpolation,tqStringInRegexp

syn case ignore

" Symbols
syn match  tqSymbol    "@\(\w\|[-*/\\:=!+<>]\)\+[ ,;\]\n]\@="
syn match  tqSymbol    "@\"[^\"]*\""
syn match  tqSymbol    "@'[^']*'"

" some representations of numbers
syn match  tqNumber    "\<\d\+\(u\=l\=\|lu\|f\)\>"
syn match  tqFloat    "\<\d\+\.\d*\(e[-+]\=\d\+\)\=[fl]\=\>"
syn match  tqFloat    "\<\d\+e[-+]\=\d\+[fl]\=\>"

syn case match

" a try to higlight paren mismatches
syn region tqParen    transparent start='(' end=')' contains=ALLBUT,tqParenError
syn match  tqParenError    ")" contained
syn region tqBlock    transparent start='{' end='}' contains=ALLBUT,tqBlockError
syn match  tqBlockError    "}" contained

hi link tqParenError tqError
hi link tqBlockError tqError

" synchronization for syntax analysis
syn sync minlines=50

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_st_syntax_inits")
    if version < 508
        let did_tq_syntax_inits = 1
        command -nargs=+ HiLink hi link <args>
    else
        command -nargs=+ HiLink hi def link <args>
    endif

    HiLink tqClassDef        Statement
    HiLink stInstMethod      Function
    HiLink stClassMethod     Function
    "  HiLink tqConstant       Constant
    HiLink tqKeyword         Statement
    HiLink tqMethod          Statement
    HiLink tqComment         Comment
    HiLink tqCharacter       Constant
    HiLink tqString          Constant
    "HiLink tqRegexp          Special
    HiLink tqSymbol          Special
    HiLink tqMessageColon    Special
    HiLink tqNumber          Type
    HiLink tqFloat           Type
    HiLink tqError           Error
    HiLink tqKeywordLiteral  Constant

    delcommand HiLink
endif

let b:current_syntax = "tq"

let &cpo = s:cpo_save
unlet s:cpo_save
