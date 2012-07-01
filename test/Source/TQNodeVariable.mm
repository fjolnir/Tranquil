#import "TQNodeVariable.h"
#import "TQProgram.h"
#import <llvm/Support/IRBuilder.h>

using namespace llvm;

@implementation TQNodeVariable
@synthesize name=_name;

+ (TQNodeVariable *)nodeWithName:(NSString *)aName
{
	return [[[self alloc] initWithName:aName] autorelease];
}

- (id)initWithName:(NSString *)aName
{
	if(!(self = [super init]))
		return nil;

	_name = [aName retain];

	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<var@ %@>", _name];
}

- (NSUInteger)hash
{
	return [_name hash];
}

- (void)dealloc
{
	[_name release];
	[super dealloc];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoError
{
	AllocaInst *alloca = aBlock.builder->CreateAlloca(aProgram.llInt8PtrTy);
	// Initialize to nil
	aBlock.builder->CreateStore(ConstantPointerNull::get(aProgram.llInt8PtrTy), alloca);
	return alloca;
}
@end
