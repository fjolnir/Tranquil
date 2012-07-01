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
@synthesize statements=_statements, name=_name;

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
	NSError *err = nil;
	for(TQNode *node in _statements) {
		[node generateCodeInModule:_module error:&err];
		if(err) {
			NSLog(@"Error: %@", err);
			return NO;
		}
	}
	// TODO: run the thing
	return YES;
}

- (NSString *)description
{
	NSMutableString *out = [NSMutableString stringWithString:@"<prog@\n"];
	for(TQNode *node in _statements) {
		[out appendFormat:@"%@\n", node];
	}
	[out appendString:@"}>"];
	return out;
}
@end

