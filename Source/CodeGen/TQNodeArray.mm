#import "TQNodeArray.h"
#import "TQProgram.h"
#import "TQNodeBlock.h"
#import "TQNodeArgument.h"
#import "TQNodeVariable.h"

using namespace llvm;

@implementation TQNodeArray
@synthesize items=_items;

+ (TQNodeArray *)node
{
	return (TQNodeArray *)[super node];
}

- (void)dealloc
{
	[_items release];
	[super dealloc];
}

- (NSString *)description
{
	NSMutableString *out = [NSMutableString stringWithString:@"<array@["];

	for(TQNode *item in _items) {
		[out appendFormat:@"%@, ", item];
	}

	[out appendString:@"]>"];
	return out;
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
	TQNode *ref = nil;

	if([self isEqual:aNode])
		return self;
	if((ref = [_items tq_referencesNode:aNode]))
		return ref;

	return nil;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
	IRBuilder<> *builder = aBlock.builder;
	Module *mod = aProgram.llModule;

	std::vector<Value *>args;
	args.push_back(mod->getOrInsertGlobal("OBJC_CLASS_$_NSPointerArray", aProgram.llInt8Ty));
	args.push_back(builder->CreateLoad(mod->getOrInsertGlobal("TQPointerArrayWithObjectsSel", aProgram.llInt8PtrTy)));
	for(TQNode *item in _items) {
		args.push_back([item generateCodeInProgram:aProgram block:aBlock error:aoErr]);
		if(*aoErr)
			return NULL;
	}
	args.push_back(builder->CreateLoad(mod->getOrInsertGlobal("TQSentinel", aProgram.llInt8PtrTy)));

	CallInst *call = builder->CreateCall(aProgram.objc_msgSend, args);
	return call;
}

@end
