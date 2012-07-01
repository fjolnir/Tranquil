#import "TQNodeBinaryOperator.h"
#import "TQNodeVariable.h"
#import "TQNodeMemberAccess.h"

using namespace llvm;

@implementation TQNodeBinaryOperator
@synthesize type=_type, left=_left, right=_right;

+ (TQNodeBinaryOperator *)nodeWithType:(TQOperatorType)aType left:(TQNode *)aLeft right:(TQNode *)aRight
{
	return [[[self alloc] initWithType:aType left:aLeft right:aRight] autorelease];
}

- (id)initWithType:(TQOperatorType)aType left:(TQNode *)aLeft right:(TQNode *)aRight
{
	if(!(self = [super init]))
		return nil;

	_type = aType;
	_left = [aLeft retain];
	_right = [aRight retain];

	return self;
}

- (void)dealloc
{
	[_left release];
	[_right release];
	[super dealloc];
}

- (BOOL)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoError
{
	BOOL isVar = [_left isMemberOfClass:[TQNodeVariable class]];
	BOOL isProperty = [_left isMemberOfClass:[TQNodeMemberAccess class]];
	TQAssertSoft(isVar || isProperty, kTQSyntaxErrorDomain, kTQInvalidAssignee, NO, @"Only variables and object properties can be assigned to");

	NSLog(@"> Assigning to %@", _left);
	// Retrieve the address of the variable
	if([_left isMemberOfClass:[TQNodeVariable class]]) {
		
	} else { // Property
		
	}

	// Assign to the left hand side
	//   Retrieve i8* objc_storeStrong(i8**, i8*)
	// char *(char*)
    //PointerType *t_ptr_i8 = PointerType::get(IntegerType::get(aModule->getContext(), 8), 0);
    //PointerType *t_ptr_ptr_i8 = PointerType::get(PointerType::get(IntegerType::get(aModule->getContext(), 8), 0), 0);

	//std::vector<Type*> ft_i8ptr__i8ptrPtr_i8Ptr_args;
	//ft_i8ptr__i8ptrPtr_i8Ptr_args.push_back(t_ptr_ptr_i8);
	//ft_i8ptr__i8ptrPtr_i8Ptr_args.push_back(t_ptr_i8);

	//FunctionType *ft_i8ptr__i8ptrPtr_i8Ptr = FunctionType::get(
		//t_ptr_i8,                      // return type
		//ft_i8ptr__i8ptrPtr_i8Ptr_args, // Argument types
		//false);                        // Variadic

	//Function *func_objc_storeStrong = aModule->getFunction("objc_storeStrong");
	//if(!func_objc_storeStrong) {
		//func_objc_storeStrong = Function::Create(
		 //[>Type=<]ft_i8ptr__i8ptrPtr_i8Ptr,
		 //[>Linkage=<]GlobalValue::ExternalLinkage,
		 //[>Name=<]"objc_storeStrong", aModule); // (external, no body)
		//func_objc_storeStrong->setCallingConv(CallingConv::C);
	//}
	//AttrListPtr  objc_lookUpClass_PAL;
	//func_objc_storeStrong->setAttributes(objc_lookUpClass_PAL);

	//CallInst *setterCall = CallInst::Create(func_objc_storeStrong, "", aBlock);
	//setterCall->setCallingConv(CallingConv::C);
	//setterCall->setTailCall(true);
	//AttrListPtr setterCall_PAL;
	//setterCall->setAttributes(setterCall_PAL);

	return YES;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<op@ %@ %c %@>", _left, _type, _right];
}
@end
