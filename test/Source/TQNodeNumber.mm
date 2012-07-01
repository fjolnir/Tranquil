#import "TQNodeNumber.h"
#import "TQProgram.h"

using namespace llvm;

static Value *_NSNumberNameConst = NULL, *_NumWithDblSel = NULL;

@implementation TQNodeNumber
@synthesize value=_value;

+ (TQNodeNumber *)nodeWithDouble:(double)aDouble
{
	return [[[self alloc] initWithDouble:aDouble] autorelease];
}

- (id)initWithDouble:(double)aDouble
{
	if(!(self = [super init]))
		return nil;

	_value = [[NSNumber alloc] initWithDouble:aDouble];

	return self;
}

- (void)dealloc
{
	[_value release];
	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<num@ %f>", _value.doubleValue];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoError
{
	llvm::Module *mod = aProgram.llModule;
	//llvm::BasicBlock *block = aBlock.basicBlock;
	llvm::IRBuilder<> *builder = aBlock.builder;

	// Returns [NSNumber numberWithDouble:_value]
	if(!_NSNumberNameConst)
		_NSNumberNameConst = builder->CreateGlobalStringPtr("NSNumber", "className_NSNumber");
	if(!_NumWithDblSel)
		_NumWithDblSel = builder->CreateGlobalStringPtr("numberWithDouble:", "sel_numberWithDouble");

	CallInst *classLookup = builder->CreateCall(aProgram.objc_getClass, _NSNumberNameConst);
	CallInst *selReg = builder->CreateCall(aProgram.sel_registerName, _NumWithDblSel);
	ConstantFP *doubleValue = ConstantFP::get(aProgram.llModule->getContext(), APFloat([_value doubleValue]));

	return builder->CreateCall3(aProgram.objc_msgSend, classLookup, selReg, doubleValue);
}
@end
