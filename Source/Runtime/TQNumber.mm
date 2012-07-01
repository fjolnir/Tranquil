#import "TQNumber.h"
#import <objc/runtime.h>
#import "TQRuntime.h"

static TQPoolInfo poolInfo = { nil, nil };
static IMP superAllocImp = NULL;

TQNumber *TQNumberTrue;
TQNumber *TQNumberFalse;

// Hack from libobjc, allows tail call optimization for objc_msgSend
extern id _objc_msgSend_hack(id, SEL)          asm("_objc_msgSend");
extern id _objc_msgSend_hack2(id, SEL, id)     asm("_objc_msgSend");


@implementation TQNumber

+ (void)load
{
	if(!superAllocImp)
		superAllocImp = method_getImplementation(class_getClassMethod(self, @selector(allocWithPoolInfo:)));

	TQNumberTrue = [[self alloc] init];
	TQNumberTrue->_doubleValue = 1;
	TQNumberFalse = [[self alloc] init];
	TQNumberFalse->_doubleValue = 0;

	IMP operatorImp;

	// ==
	IMP imp = imp_implementationWithBlock(^(TQNumber *a, TQNumber *b) { return a->_doubleValue == b->_doubleValue ? TQNumberTrue : TQNumberFalse; });
	class_addMethod(self, TQEqOpSel, imp, "@@:@");
	// !=
	imp = imp_implementationWithBlock(^(TQNumber *a, TQNumber *b)     { return  a->_doubleValue != b->_doubleValue? TQNumberFalse : TQNumberTrue; });
	class_addMethod(self, TQNeqOpSel, imp, "@@:@");

	// + (Unimplemented by default)
	operatorImp = class_getMethodImplementation(self, @selector(add:));
	imp = imp_implementationWithBlock(^(TQNumber *a, TQNumber *b) { return operatorImp(a, @selector(add:), b); });
	class_addMethod(self, TQAddOpSel, imp, "@@:@");
	// - (Unimplemented by default)
	operatorImp = class_getMethodImplementation(self, @selector(subtract:));
	imp = imp_implementationWithBlock(^(TQNumber *a, TQNumber *b) { return operatorImp(a, @selector(subtract:), b); });
	class_addMethod(self, TQSubOpSel, imp, "@@:@");
	// unary - (Unimplemented by default)
	operatorImp = class_getMethodImplementation(self, @selector(negate:));
	imp = imp_implementationWithBlock(^(TQNumber *a)       { return operatorImp(a, @selector(negate:)); });
	class_addMethod(self, TQUnaryMinusOpSel, imp, "@@:");

	// * (Unimplemented by default)
	operatorImp = class_getMethodImplementation(self, @selector(multiply:));
	imp = imp_implementationWithBlock(^(TQNumber *a, TQNumber *b) { return operatorImp(a, @selector(multiply:), b);  });
	class_addMethod(self, TQMultOpSel, imp, "@@:@");
	// / (Unimplemented by default)
	operatorImp = class_getMethodImplementation(self, @selector(divideBy:));
	imp = imp_implementationWithBlock(^(TQNumber *a, TQNumber *b) { return operatorImp(a, @selector(divideBy:), b); });
	class_addMethod(self, TQDivOpSel, imp, "@@:@");

	// <
	operatorImp = class_getMethodImplementation(self, @selector(compare:));
	imp = imp_implementationWithBlock(^(TQNumber *a, TQNumber *b) {
		return ((NSComparisonResult)operatorImp(a, @selector(compare:), b) == NSOrderedAscending) ? TQNumberTrue : TQNumberFalse;
	});
	class_addMethod(self, TQLTOpSel, imp, "@@:@");
	// >
	imp = imp_implementationWithBlock(^(TQNumber *a, TQNumber *b) {
		return ((NSComparisonResult)operatorImp(a, @selector(compare:), b)  == NSOrderedDescending) ? TQNumberTrue : TQNumberFalse;
	});
	class_addMethod(self, TQGTOpSel, imp, "@@:@");
	// <=
	imp = imp_implementationWithBlock(^(TQNumber *a, TQNumber *b) {
		return ((NSComparisonResult)operatorImp(a, @selector(compare:), b)  != NSOrderedDescending) ? TQNumberTrue : TQNumberFalse;
	});
	class_addMethod(self, TQLTEOpSel, imp, "@@:@");
	// >=
	imp = imp_implementationWithBlock(^(TQNumber *a, TQNumber *b) {
		return ((NSComparisonResult)operatorImp(a, @selector(compare:), b)  != NSOrderedAscending) ? TQNumberTrue : TQNumberFalse;
	});
	class_addMethod(self, TQGTEOpSel, imp, "@@:@");
}

+ (TQPoolInfo *)poolInfo
{
	return &poolInfo;
}

+ (id)allocWithZone:(NSZone *)zone
{
	return superAllocImp(self, @selector(allocWithPoolInfo:), &poolInfo);
}

+ (TQNumber *)numberWithDouble:(double)aValue
{
	// This one gets called quite frequently, so we cache the imps required to allocate
	static IMP allocImp, initImp, autoreleaseImp;
	if(!allocImp) {
		allocImp = method_getImplementation(class_getClassMethod(self, @selector(alloc)));
		initImp = class_getMethodImplementation(self, @selector(init));
		autoreleaseImp = class_getMethodImplementation(self, @selector(autorelease));
	}
	TQNumber *ret = initImp(allocImp(self, @selector(alloc)), @selector(init));
	ret->_doubleValue = aValue;
	return autoreleaseImp(ret, @selector(autorelease));
}

- (TQNumber *)add:(TQNumber *)b
{
	return [TQNumber numberWithDouble:_doubleValue + b->_doubleValue];
}
- (TQNumber *)subtract:(TQNumber *)b
{
	return [TQNumber numberWithDouble:_doubleValue - b->_doubleValue];
}
- (TQNumber *)negate
{
	return [TQNumber numberWithDouble:-_doubleValue];
}

- (TQNumber *)multiply:(TQNumber *)b
{
	return [TQNumber numberWithDouble:_doubleValue * b->_doubleValue];
}
- (TQNumber *)divideBy:(TQNumber *)b
{
	return [TQNumber numberWithDouble:_doubleValue / b->_doubleValue];
}

- (TQNumber *)addDouble:(double)b
{
	return [TQNumber numberWithDouble:_doubleValue + b];
}
- (TQNumber *)subtractDouble:(double)b
{
	return [TQNumber numberWithDouble:_doubleValue - b];
}
- (TQNumber *)multiplyDouble:(double)b
{
	return [TQNumber numberWithDouble:_doubleValue * b];
}
- (TQNumber *)divideByDouble:(double)b
{
	return [TQNumber numberWithDouble:_doubleValue / b];
}


- (NSComparisonResult)compare:(id)object
{
	if(object_getClass(object) != self->isa)
		return NSOrderedAscending;
	TQNumber *b = object;
	if(_doubleValue > b->_doubleValue)
		return NSOrderedDescending;
	else if(_doubleValue < b->_doubleValue)
		return NSOrderedAscending;
	else
		return NSOrderedSame;
}

- (id)if:(condBlock)ifBlock else:(condBlock)elseBlock
{
	if((BOOL)_doubleValue)
		return ifBlock();
	else
		return elseBlock();
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%f", _doubleValue];
}
@end
