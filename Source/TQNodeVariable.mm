#import "TQNodeVariable.h"
#import "TQProgram.h"
#import <llvm/Support/IRBuilder.h>

using namespace llvm;

@implementation TQNodeVariable
@synthesize name=_name, alloca=_alloca;

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

- (llvm::Type *)captureStructTypeInProgram:(TQProgram *)aProgram
{
	static Type *captureType = NULL;
	if(captureType)
		return captureType;

	Type *i8PtrTy = aProgram.llInt8PtrTy;
	Type *intTy   = aProgram.llIntTy;

	captureType = StructType::create("struct._block_byref",
	                                 i8PtrTy, // isa
	                                 i8PtrTy, // forwarding
	                                 intTy,   // flags (refcount)
	                                 intTy,   // size ( = sizeof(id))
	                                 i8PtrTy, // byref_keep(void *dest, void *src)
	                                 i8PtrTy, // byref_dispose(void *)
	                                 i8PtrTy, // Captured variable (id)
	                                 NULL);
	return captureType;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                 error:(NSError **)aoError
{
	TQNodeVariable *existingVar = nil;

	if((existingVar = [aBlock.locals objectForKey:_name]) && existingVar != self)
		return [existingVar generateCodeInProgram:aProgram block:aBlock error:aoError];
	else
		[aBlock.locals setObject:self forKey:_name];

	IRBuilder<> *builder = aBlock.builder;
	if(_alloca)
		return  builder->CreateLoad(_alloca);
	AllocaInst *alloca = builder->CreateAlloca(aProgram.llInt8PtrTy);
	// Initialize to nil
	builder->CreateStore(ConstantPointerNull::get(aProgram.llInt8PtrTy), alloca);
	_alloca = alloca;
	return builder->CreateLoad(alloca);
}

- (llvm::Value *)store:(llvm::Value *)aValue
             inProgram:(TQProgram *)aProgram
                 block:(TQNodeBlock *)aBlock
                 error:(NSError **)aoError
{
	if(!_alloca) {
		if(![self generateCodeInProgram:aProgram block:aBlock error:aoError])
			return NULL;
	}
	return aBlock.builder->CreateStore(aValue, _alloca);
	//aBlock.builder->CreateCall2(aProgram.objc_storeStrong, _alloca, aValue);
}
@end
