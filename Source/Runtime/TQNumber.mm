#import "TQNumber.h"

@implementation TQNumber

+ (volatile BunchInfo *) bunchInfo
{
   static volatile BunchInfo bunchInfo;
   return( &bunchInfo);
}

+ (TQNumber *)numberWithDouble:(double)aValue
{
	TQNumber *ret = [[self alloc] init];
	ret->_doubleValue = aValue;
	return [ret autorelease];
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
