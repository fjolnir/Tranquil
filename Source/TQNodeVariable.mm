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
	IRBuilder<> *builder = aBlock.builder;
	if(_alloca)
		return builder->CreateLoad(builder->CreateStructGEP(_alloca, 6));

	TQNodeVariable *existingVar = nil;
	if((existingVar = [aBlock.locals objectForKey:_name]) && existingVar != self) {
		Value *ret = [existingVar generateCodeInProgram:aProgram block:aBlock error:aoError];
		_alloca = existingVar.alloca;
		return ret;
	} else
		[aBlock.locals setObject:self forKey:_name];

	Type *intTy   = aProgram.llIntTy;
	Type *i8PtrTy = aProgram.llInt8PtrTy;

	Type *byRefType = [self captureStructTypeInProgram:aProgram];
	AllocaInst *alloca = builder->CreateAlloca(byRefType, 0);
	// Initialize the variable to nil
	builder->CreateStore(ConstantPointerNull::get(aProgram.llInt8PtrTy), builder->CreateStructGEP(alloca, 0, "capture.isa"));
	builder->CreateStore(builder->CreateBitCast(alloca, i8PtrTy), builder->CreateStructGEP(alloca, 1, "capture.forwarding"));
	builder->CreateStore(ConstantInt::get(intTy, TQ_BLOCK_HAS_COPY_DISPOSE), builder->CreateStructGEP(alloca, 2, "capture.flags"));
	Constant *size = ConstantExpr::getTruncOrBitCast(ConstantExpr::getSizeOf(byRefType), intTy);
	builder->CreateStore(size, builder->CreateStructGEP(alloca, 3, "capture.size"));
	builder->CreateStore(ConstantPointerNull::get(aProgram.llInt8PtrTy), builder->CreateStructGEP(alloca, 4, "capture.byref_keep"));
	builder->CreateStore(ConstantPointerNull::get(aProgram.llInt8PtrTy), builder->CreateStructGEP(alloca, 5, "capture.byref_dispose"));
	builder->CreateStore(ConstantPointerNull::get(aProgram.llInt8PtrTy), builder->CreateStructGEP(alloca, 6, "capture.marked_variable"));
	
	_alloca = alloca;
	return builder->CreateLoad(builder->CreateStructGEP(alloca, 6));
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
	IRBuilder<> *builder = aBlock.builder;
	Value *forwarding = builder->CreateStructGEP(_alloca, 1);

	return aBlock.builder->CreateStore(aValue, builder->CreateStructGEP(_alloca, 6));
}
@end
