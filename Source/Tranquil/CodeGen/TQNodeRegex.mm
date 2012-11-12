#import "TQNodeRegex.h"
#import "TQNode+Private.h"
#import "TQNodeBlock.h"
#import "TQProgram.h"

using namespace llvm;

@implementation TQNodeRegex
@synthesize options=_opts, pattern=_pattern;

+ (TQNodeRegex *)nodeWithPattern:(OFMutableString *)aPattern
{
    TQNodeRegex *ret = (TQNodeRegex *)[super node];
    ret.pattern = aPattern;
    return ret;
}

- (void)dealloc
{
    [_pattern release];
    [super dealloc];
}

- (OFString *)description
{
    return [OFString stringWithFormat:@"<regex@ %@>", self.value];
}

- (void)append:(OFString *)aStr
{
    [_pattern appendString:aStr];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(TQError **)aoErr
{
    //TODO: Rewrite regex code
    return ConstantPointerNull::get(aProgram.llInt8PtrTy);
#if 0
    // Generate the regex string
    NSRegularExpression *splitRegex = [NSRegularExpression regularExpressionWithPattern:@"/(([\\/]|[^/])*)/([im]*)"
                                                                                options:0
                                                                                  error:nil];
    NSTextCheckingResult *match = [splitRegex firstMatchInString:_pattern options:0 range:NSMakeRange(0, [_pattern length])];
    assert(match != nil);
    of_range_t patRange = [match rangeAtIndex:1];
    of_range_t optRange = [match rangeAtIndex:2];

    OFString *pattern;
    if(patRange.length > 0)
        pattern = [_pattern substringWithRange:patRange];
    else
        pattern = @"";

    _opts = 0;
    if(optRange.length > 0) {
        OFString *optStr  = [_pattern substringWithRange:[match rangeAtIndex:3]];
        if([optStr rangeOfString:@"i"].location != OF_NOT_FOUND)
            _opts |= NSRegularExpressionCaseInsensitive;
        if([optStr rangeOfString:@"m"].location != OF_NOT_FOUND)
            _opts |= NSRegularExpressionAnchorsMatchLines;
    }
    [super setValue:[[pattern mutableCopy] autorelease]];

    // Compile
    Module *mod = aProgram.llModule;
    llvm::IRBuilder<> *builder = aBlock.builder;

    // Returns [TQRegularExpression tq_regularExpressionWithPattern:options:]
    Value *patVal   = [super generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    Value *selector = builder->CreateLoad(mod->getOrInsertGlobal("TQRegexWithPatSel", aProgram.llInt8PtrTy));
    Value *klass    = mod->getOrInsertGlobal("OBJC_CLASS_$_TQRegularExpression", aProgram.llInt8Ty);
    Value *optsVal  = ConstantInt::get(aProgram.llIntTy, _opts);

    Value *ret = builder->CreateCall4(aProgram.objc_msgSend, klass, selector, patVal, optsVal);
    [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];
    return ret;
#endif
}
@end
