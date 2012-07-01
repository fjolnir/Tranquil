#import "TQNodeRegex.h"
#import "TQProgram.h"

using namespace llvm;

@implementation TQNodeRegex
@synthesize pattern=_pattern;

+ (TQNodeRegex *)nodeWithPattern:(NSString *)aPattern
{
	TQNodeRegex *regex = [[self alloc] init];
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

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoError
{
	Module *mod = aProgram.llModule;
	llvm::IRBuilder<> *builder = aBlock.builder;

	// Returns [NSRegularExpression tq_regularExpressionWithUTF8String:options:]
	NSRegularExpression *splitRegex = [NSRegularExpression regularExpressionWithPattern:@"\\/((\\\\\\/)|[^\\/])*\\/[im]*"
	                                                                            options:0
	                                                                              error:nil];
	NSTextCheckingResult *match = [splitRegex firstMatchInString:_pattern options:0 range:NSMakeRange(0, [_pattern length])];
	assert(match != nil);
	NSString *pattern = [_pattern substringWithRange:[match rangeAtIndex:1]];
	NSString *optStr  = [_pattern substringWithRange:[match rangeAtIndex:2]];
	NSRegularExpressionOptions opts = 0;
	if([optStr rangeOfString:@"i"].location != NSNotFound)
		opts |= NSRegularExpressionCaseInsensitive;
	if([optStr rangeOfString:@"m"].location != NSNotFound)
		opts |= NSRegularExpressionAnchorsMatchLines;
	
	Value *selector = builder->CreateLoad(mod->getOrInsertGlobal("TQRegexWithPatSel", aProgram.llInt8PtrTy));
	Value *klass    = mod->getOrInsertGlobal("OBJC_CLASS_$_NSRegularExpression", aProgram.llInt8Ty);
	Value *patVal   = builder->CreateGlobalStringPtr([pattern UTF8String]);
	Value *optsVal  = ConstantInt::get(aProgram.llIntTy, opts);

	return builder->CreateCall4(aProgram.objc_msgSend, klass, selector, patVal, optsVal);
}
@end
