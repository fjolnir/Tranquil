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
@synthesize root=_root, name=_name;

+ (TQProgram *)programWithName:(NSString *)aName
{
	return [[[self alloc] initWithName:aName] autorelease];
}

- (id)initWithName:(NSString *)aName
{
	if(!(self = [super init]))
		return nil;

	_name = [aName retain];
	_module = new Module([_name UTF8String], getGlobalContext());

	return self;
}

- (void)dealloc
{
	delete _module;
	[super dealloc];
}

- (BOOL)run
{
	// Create the main function
	// int()
	std::vector<Type*>ft_i32__void_args;
	FunctionType* ft_i32__void = FunctionType::get(
		/*Result=*/IntegerType::get(_module->getContext(), 32),
		/*Params=*/ft_i32__void_args,
		/*isVarArg=*/false);
	
	Function* func_main = _module->getFunction("main");
	if (!func_main) {
		func_main = Function::Create(
			/*Type=*/ft_i32__void,
			/*Linkage=*/GlobalValue::ExternalLinkage,
			/*Name=*/"main", _module); 
		func_main->setCallingConv(CallingConv::C);
	}
	AttrListPtr func_main_PAL;
	{
		SmallVector<AttributeWithIndex, 4> Attrs;
		AttributeWithIndex PAWI;
		PAWI.Index = 4294967295U; PAWI.Attrs = 0  | Attribute::StackProtect | Attribute::UWTable;
		Attrs.push_back(PAWI);
		func_main_PAL = AttrListPtr::get(Attrs.begin(), Attrs.end());
	}
	func_main->setAttributes(func_main_PAL);

	BasicBlock *block = BasicBlock::Create(_module->getContext(), "", func_main, 0);

	NSError *err = nil;
	[_root generateCodeInModule:_module block:block error:&err];
	if(err) {
		NSLog(@"Error: %@", err);
		//return NO;
	}
	// Return from main
	ConstantInt* const_int32_zero = ConstantInt::get(_module->getContext(), APInt(32, StringRef("0"), 10));
	ReturnInst::Create(_module->getContext(), const_int32_zero, block);

	//  Output LLVM - IR
	verifyModule(*_module, PrintMessageAction);
	PassManager PM;
	PM.add(createPrintModulePass(&outs()));
	PM.run(*_module);

	return YES;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<prog@\n%@\n}>", _root];
}
@end

