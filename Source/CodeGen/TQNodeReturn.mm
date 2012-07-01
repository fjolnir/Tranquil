#import "TQNodeReturn.h"
#import "TQProgram.h"
#import "TQNodeVariable.h"
#import "TQNodeBlock.h"
#import "TQNodeMessage.h"
#import "TQNodeCall.h"

using namespace llvm;

@implementation TQNodeReturn
@synthesize value=_value;
+ (TQNodeReturn *)nodeWithValue:(TQNode *)aValue
{
	return [[[self alloc] initWithValue:aValue] autorelease];
}

- (id)initWithValue:(TQNode *)aValue
{
	if(!(self = [super init]))
		return nil;

	_value = [aValue retain];

	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<ret@ %@>", _value];
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
	TQNode *ref = nil;
	if([aNode isEqual:self])
		return self;
	else if((ref = [_value referencesNode:aNode]))
		return ref;
	return nil;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoError
{
	IRBuilder<> *builder = aBlock.builder;

	// Release any blocks created inside the block we're returning from


	// Return
	Value *retVal = [_value generateCodeInProgram:aProgram block:aBlock error:aoError];
	// If the returned instruction is not a call, then we need to prepare it to be returned (For example to copy a block
	// to the heap if necessary)
	if(![_value isKindOfClass:[TQNodeMessage class]] && ![_value isKindOfClass:[TQNodeCall class]])
		retVal = builder->CreateCall(aProgram.TQPrepareObjectForReturn, retVal);
	//else if([_value isKindOfClass:[TQNodeCall class]])
		//((CallInst*)retVal)->setTailCall(true);
	return builder->CreateRet(retVal);
}
@end
