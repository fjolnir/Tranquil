#import "TQNodeRegex.h"
#import "../TQProgram.h"

using namespace llvm;

@implementation TQNodeRegex
@synthesize pattern=_pattern;

+ (TQNodeRegex *)nodeWithPattern:(NSString *)aPattern
{
    TQNodeRegex *regex = [self new];
    regex.pattern = aPattern;
    return [regex autorelease];
}

- (void)dealloc
{
    [_pattern release];
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<regex@ %@>", _pattern];
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    return [aNode isEqual:self] ? self : nil;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    // Nothing to iterate
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    Module *mod = aProgram.llModule;
    llvm::IRBuilder<> *builder = aBlock.builder;

    // Returns [NSRegularExpression tq_regularExpressionWithUTF8String:options:]
    NSRegularExpression *splitRegex = [NSRegularExpression regularExpressionWithPattern:@"/(([\\/]|[^/])*)/([im]*)"
                                                                                options:0
                                                                                  error:nil];
    NSTextCheckingResult *match = [splitRegex firstMatchInString:_pattern options:0 range:NSMakeRange(0, [_pattern length])];
    assert(match != nil);
    NSRange patRange = [match rangeAtIndex:1];
    NSRange optRange = [match rangeAtIndex:2];

    NSString *pattern;
    if(patRange.length > 0)
        pattern = [_pattern substringWithRange:patRange];
    else
        pattern = @"";

    NSRegularExpressionOptions opts = 0;
    if(optRange.length > 0) {
        NSString *optStr  = [_pattern substringWithRange:[match rangeAtIndex:3]];
        if([optStr rangeOfString:@"i"].location != NSNotFound)
            opts |= NSRegularExpressionCaseInsensitive;
        if([optStr rangeOfString:@"m"].location != NSNotFound)
            opts |= NSRegularExpressionAnchorsMatchLines;
    }

    Value *selector = builder->CreateLoad(mod->getOrInsertGlobal("TQRegexWithPatSel", aProgram.llInt8PtrTy));
    Value *klass    = mod->getOrInsertGlobal("OBJC_CLASS_$_TQRegularExpression", aProgram.llInt8Ty);
    Value *patVal   = [aProgram getGlobalStringPtr:pattern inBlock:aBlock];
    Value *optsVal  = ConstantInt::get(aProgram.llIntTy, opts);

    return builder->CreateCall4(aProgram.objc_msgSend, klass, selector, patVal, optsVal);
}
@end
