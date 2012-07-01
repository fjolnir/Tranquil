#import "TQNumber.h"
#import <objc/runtime.h>

@implementation TQNumber

+ (TQPoolInfo *)poolInfo
{
  static TQPoolInfo *poolInfo = nil;
  if (!poolInfo) poolInfo = [[TQPoolInfo alloc] init];
  return poolInfo;
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
	return [TQNumber numberWithDouble:_doubleValue + b.doubleValue];
}
- (TQNumber *)subtract:(TQNumber *)b
{
	return [TQNumber numberWithDouble:_doubleValue - b.doubleValue];
}
- (TQNumber *)negate
{
	return [TQNumber numberWithDouble:-1.0*_doubleValue];
}

- (TQNumber *)multiply:(TQNumber *)b
{
	return [TQNumber numberWithDouble:_doubleValue * b.doubleValue];
}
- (TQNumber *)divide:(TQNumber *)b
{
	return [TQNumber numberWithDouble:_doubleValue / b.doubleValue];
}

- (NSComparisonResult)compare:(id)object
{
	if(![object isKindOfClass:[TQNumber class]])
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
	if(_doubleValue > 0.00000001)
		return ifBlock();
	else
		return elseBlock();
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%f", _doubleValue];
}
@end
