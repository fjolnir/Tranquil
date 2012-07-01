#import "TQNodeOperator.h"
#import "TQNodeVariable.h"
#import "TQNodeMemberAccess.h"
#import "TQProgram.h"

using namespace llvm;

@implementation TQNodeOperator
@synthesize type=_type, left=_left, right=_right;

+ (TQNodeOperator *)nodeWithType:(TQOperatorType)aType left:(TQNode *)aLeft right:(TQNode *)aRight
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

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoError
{
	if(_type == '=') {
		BOOL isVar = [_left isMemberOfClass:[TQNodeVariable class]];
		BOOL isProperty = [_left isMemberOfClass:[TQNodeMemberAccess class]];
		BOOL isGetterOp = [_left isMemberOfClass:[self class]] && [(TQNodeOperator*)_left type] == kTQOperatorGetter;
		TQAssertSoft(isVar || isProperty || isGetterOp, kTQSyntaxErrorDomain, kTQInvalidAssignee, NO, @"Only variables and object properties can be assigned to");

		Value *right = [_right generateCodeInProgram:aProgram block:aBlock error:aoError];
		
		if(isGetterOp) {
			// Call []=::
			TQNodeOperator *setterOp = (TQNodeOperator *)_left;
			Value *selector  = aProgram.llModule->getOrInsertGlobal("TQSetterOpSel", aProgram.llInt8PtrTy);
			IRBuilder<> *builder = aBlock.builder;
			Value *key = [setterOp.right generateCodeInProgram:aProgram block:aBlock error:aoError];
			Value *settee = [setterOp.left generateCodeInProgram:aProgram block:aBlock error:aoError];
			if(*aoError)
				return NULL;
			return builder->CreateCall4(aProgram.objc_msgSend, settee, builder->CreateLoad(selector), right, key);
		} else
			[(TQNodeVariable *)_left store:right inProgram:aProgram block:aBlock error:aoError];
		return [_left generateCodeInProgram:aProgram block:aBlock error:aoError];
	} else {
		Value *left  = [_left generateCodeInProgram:aProgram block:aBlock error:aoError];
		Value *right = [_right generateCodeInProgram:aProgram block:aBlock error:aoError];
		
		Value *selector = NULL;
		switch(_type) {
			case kTQOperatorLesser:
				selector  = aProgram.llModule->getOrInsertGlobal("TQLTOpSel", aProgram.llInt8PtrTy);
				break;
			case kTQOperatorGreater:
				selector  = aProgram.llModule->getOrInsertGlobal("TQGTOpSel", aProgram.llInt8PtrTy);
				break;
			case kTQOperatorMultiply:
				selector  = aProgram.llModule->getOrInsertGlobal("TQMultOpSel", aProgram.llInt8PtrTy);
				break;
			case kTQOperatorDivide:
				selector  = aProgram.llModule->getOrInsertGlobal("TQDivOpSel", aProgram.llInt8PtrTy);
				break;
			case kTQOperatorAdd:
				selector  = aProgram.llModule->getOrInsertGlobal("TQAddOpSel", aProgram.llInt8PtrTy);
				break;
			case kTQOperatorSubtract:
				selector  = aProgram.llModule->getOrInsertGlobal("TQSubOpSel", aProgram.llInt8PtrTy);
				break;
			case kTQOperatorEqual:
				selector  = aProgram.llModule->getOrInsertGlobal("TQEqOpSel", aProgram.llInt8PtrTy);
				break;
			case kTQOperatorInequal:
				selector  = aProgram.llModule->getOrInsertGlobal("TQNeqOpSel", aProgram.llInt8PtrTy);
				break;
			case kTQOperatorGreaterOrEqual:
				selector  = aProgram.llModule->getOrInsertGlobal("TQGTEOpSel", aProgram.llInt8PtrTy);
				break;
			case kTQOperatorLesserOrEqual:
				selector  = aProgram.llModule->getOrInsertGlobal("TQLTEOpSel", aProgram.llInt8PtrTy);
				break;
			case kTQOperatorGetter:
				selector  = aProgram.llModule->getOrInsertGlobal("TQGetterOpSel", aProgram.llInt8PtrTy);
				break;
			default:
				TQAssertSoft(NO, kTQGenericErrorDomain, kTQGenericError, NULL, @"Unknown binary operator");
		}
		IRBuilder<> *builder = aBlock.builder;
		return builder->CreateCall3(aProgram.objc_msgSend, left, builder->CreateLoad(selector), right);
	}
}

- (NSString *)description
{
	if(_type == kTQOperatorGetter)
		return [NSString stringWithFormat:@"<op@ %@[%@]>", _left, _right];
	else
		return [NSString stringWithFormat:@"<op@ %@ %c %@>", _left, _type, _right];
}
@end
