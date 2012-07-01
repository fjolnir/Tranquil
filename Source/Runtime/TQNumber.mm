#import "TQNumber.h"
#import <objc/runtime.h>

static TQPoolInfo *poolInfo = nil;
static IMP superAllocImp = NULL;

@implementation TQNumber

+ (void)load
{
	if(!poolInfo)
		poolInfo = [[TQPoolInfo alloc] init];
	if(!superAllocImp)
		superAllocImp = method_getImplementation(class_getClassMethod(self, @selector(allocWithPoolInfo:)));
}

+ (TQPoolInfo *)poolInfo
{
	return poolInfo;
}

+ (id)allocWithZone:(NSZone *)zone
{
	return superAllocImp(self, @selector(allocWithPoolInfo:), poolInfo);
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
- (TQNumber *)divideBy:(TQNumber *)b
{
	return [TQNumber numberWithDouble:_doubleValue / b.doubleValue];
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
