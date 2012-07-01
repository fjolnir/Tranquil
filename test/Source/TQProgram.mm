#include "TQProgram.h"

#include <llvm/LLVMContext.h>
#include <llvm/DerivedTypes.h>
#include <llvm/Constants.h>
#include <llvm/GlobalVariable.h>
#include <llvm/Function.h>
#include <llvm/CallingConv.h>
#include <llvm/BasicBlock.h>
#include <llvm/Instructions.h>
#include <llvm/InlineAsm.h>
#include <llvm/Support/FormattedStream.h>
#include <llvm/Support/MathExtras.h>
#include <llvm/Pass.h>
#include <llvm/PassManager.h>
#include <llvm/ADT/SmallVector.h>
#include <llvm/Analysis/Verifier.h>
#include <llvm/Assembly/PrintModulePass.h>

using namespace llvm;




@implementation TQProgram
@synthesize  root=_root, name=_name, llModule=_llModule, llVoidTy=_llVoidTy, llInt8Ty=_llInt8Ty, llInt16Ty=_llInt16Ty,
llInt32Ty=_llInt32Ty, llInt64Ty=_llInt64Ty, llFloatTy=_llFloatTy, llDoubleTy=_llDoubleTy, llIntTy=_llIntTy, llIntPtrTy=_llIntPtrTy, llSizeTy=_llSizeTy, llPtrDiffTy=_llPtrDiffTy, llVoidPtrTy=_llVoidPtrTy, llInt8PtrTy=_llInt8PtrTy, llVoidPtrPtrTy=_llVoidPtrPtrTy, llInt8PtrPtrTy=_llInt8PtrPtrTy, llPointerWidthInBits=_llPointerWidthInBits, llPointerAlignInBytes=_llPointerAlignInBytes, llPointerSizeInBytes=_llPointerSizeInBytes;

+ (TQProgram *)programWithName:(NSString *)aName
{
	return [[[self alloc] initWithName:aName] autorelease];
}

- (id)initWithName:(NSString *)aName
{
	if(!(self = [super init]))
		return nil;

	_name = [aName retain];
	_llModule = new Module([_name UTF8String], getGlobalContext());

	llvm::LLVMContext &ctx = _llModule->getContext();
	_llVoidTy               = llvm::Type::getVoidTy(ctx);
	_llInt8Ty               = llvm::Type::getInt8Ty(ctx);
	_llInt16Ty              = llvm::Type::getInt16Ty(ctx);
	_llInt32Ty              = llvm::Type::getInt32Ty(ctx);
	_llInt64Ty              = llvm::Type::getInt64Ty(ctx);
	_llFloatTy              = llvm::Type::getFloatTy(ctx);
	_llDoubleTy             = llvm::Type::getDoubleTy(ctx);
	_llPointerWidthInBits   = 64;
	_llPointerAlignInBytes  = 8;
	_llIntTy                = llvm::IntegerType::get(ctx, 32);
	_llIntPtrTy             = llvm::IntegerType::get(ctx, _llPointerWidthInBits);
	_llInt8PtrTy            = _llInt8Ty->getPointerTo(0);
	_llInt8PtrPtrTy         = _llInt8PtrTy->getPointerTo(0);

	return self;
}

- (void)dealloc
{
	delete _llModule;
	[super dealloc];
}

- (BOOL)run
{
	// Create the main function
	// int()
	//std::vector<Type*>ft_i32__void_args;
	//FunctionType* ft_i32__void = FunctionType::get(
		//[>Result=<]IntegerType::get(_llModule->getContext(), 32),
		//[>Params=<]ft_i32__void_args,
		//[>isVarArg=<]false);
	
	//Function* func_main = _llModule->getFunction("main");
	//if (!func_main) {
		//func_main = Function::Create(
			//[>Type=<]ft_i32__void,
			//[>Linkage=<]GlobalValue::ExternalLinkage,
			//[>Name=<]"main", _llModule); 
		//func_main->setCallingConv(CallingConv::C);
	//}
	//AttrListPtr func_main_PAL;
	//{
		//SmallVector<AttributeWithIndex, 4> Attrs;
		//AttributeWithIndex PAWI;
		//PAWI.Index = 4294967295U; PAWI.Attrs = 0  | Attribute::StackProtect | Attribute::UWTable;
		//Attrs.push_back(PAWI);
		//func_main_PAL = AttrListPtr::get(Attrs.begin(), Attrs.end());
	//}
	//func_main->setAttributes(func_main_PAL);

	//BasicBlock *block = BasicBlock::Create(_llModule->getContext(), "", func_main, 0);

NSLog(@"Testing objc_storeWeak");
	//llvm::GlobalValue *strw = _llModule->getNamedValue("objc_storeWeak");
	//NSLog(@"Returned %p", strw);
	NSError *err = nil;
	_root.name = @"main";
	[_root generateCodeInProgram:self block:nil error:&err];
	if(err) {
		NSLog(@"Error: %@", err);
		//return NO;
	}
	// Return from main
	//ConstantInt* const_int32_zero = ConstantInt::get(_llModule->getContext(), APInt(32, StringRef("0"), 10));
	//ReturnInst::Create(_llModule->getContext(), const_int32_zero, block);

	//  Output LLVM - IR
	verifyModule(*_llModule, PrintMessageAction);
	PassManager PM;
	PM.add(createPrintModulePass(&outs()));
	PM.run(*_llModule);

	return YES;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<prog@\n%@\n}>", _root];
}

#pragma mark - ARC Operations

//- ()retainValue:(llvm::Value *)aValue
//{
//}
@end

