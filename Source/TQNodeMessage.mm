#import "TQNodeMessage.h"
#import "TQProgram.h"
#import "TQNodeArgument.h"

using namespace llvm;

@implementation TQNodeMessage
@synthesize receiver=_receiver, arguments=_arguments;

+ (TQNodeMessage *)nodeWithReceiver:(TQNode *)aNode
{
	return [[[self alloc] initWithReceiver:aNode] autorelease];
}

- (id)initWithReceiver:(TQNode *)aNode
{
	if(!(self = [super init]))
		return nil;

	_receiver = [aNode retain];
	_arguments = [[NSMutableArray alloc] init];

	return self;
}

- (void)dealloc
{
	[_receiver release];
	[_arguments release];
	[super dealloc];
}

- (NSString *)description
{
	NSMutableString *out = [NSMutableString stringWithString:@"<msg@ "];
	[out appendFormat:@"%@ ", _receiver];

	for(TQNodeArgument *arg in _arguments) {
		[out appendFormat:@"%@ ", arg];
	}

	[out appendString:@".>"];
	return out;
}

- (NSString *)selector
{
	NSMutableString *selStr = [NSMutableString string];
	if(_arguments.count == 1 && ![[_arguments objectAtIndex:0] passedNode])
		[selStr appendString:[[_arguments objectAtIndex:0] identifier]];
	else {
		for(TQNodeArgument *arg in _arguments) {
			[selStr appendFormat:@"%@:", arg.identifier];
		}
	}
	return selStr;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
	llvm::IRBuilder<> *builder = aBlock.builder;

	Value *selector =  builder->CreateGlobalStringPtr([[self selector] UTF8String], "selector");

	CallInst *selReg = builder->CreateCall(aProgram.sel_registerName, selector);

	std::vector<Value*> args;
	args.push_back([_receiver generateCodeInProgram:aProgram block:aBlock error:aoErr]);
	args.push_back(selReg);

	for(TQNodeArgument *arg in _arguments) {
		if(!arg.passedNode)
			break;
		args.push_back([arg generateCodeInProgram:aProgram block:aBlock error:aoErr]);
	}

	return builder->CreateCall(aProgram.objc_msgSend, args);
}

@end
