#import "TQPooledObject.h"
#import <malloc/malloc.h>
#import <objc/runtime.h>

#define COMPLAIN_MISSING_IMP @"Class %@ needs this code:\n\
+ (TQPoolInfo *) poolInfo\n\
{\n\
  static TQPoolInfo *poolInfo = nil;\n\
  if (!poolInfo) poolInfo = [[TQPoolInfo alloc] init];\n\
  return poolInfo;\n\
}"

#define COMPLAIN_MISSING_ALLOC @"Class %@ needs this code:\n\
+ (id)allocWithZone:(NSZone *)zone\n\
{\n\
	static IMP superAllocImp = NULL;\n\
	if(!superAllocImp)\n\
		superAllocImp = method_getImplementation(class_getClassMethod(self, @selector(allocWithPoolInfo:)));\n\
	return superAllocImp(self, @selector(allocWithPoolInfo:), poolInfo);\n\
}"


@implementation TQPoolInfo
// empty
@end

#ifndef DISABLE_MEMORY_POOLING

@implementation TQPooledObject

+ (id)allocWithZone:(NSZone *)zone
{
	[NSException raise:NSGenericException format:COMPLAIN_MISSING_IMP, self];
	return nil;
}

+ (id)allocWithPoolInfo:(TQPoolInfo *)poolInfo
{
	if(!poolInfo->poolClass) // first allocation
	{
		poolInfo->poolClass = self;
		poolInfo->lastElement = NULL;
	}
	else
	{
		if (poolInfo->poolClass != self)
			[NSException raise:NSGenericException format:COMPLAIN_MISSING_IMP, self];
	}

	if (!poolInfo->lastElement)
	{
		// pool is empty -> allocate
		TQPooledObject *object = NSAllocateObject(self, 0, NULL);
		object->_retainCount = 1;
		object->_poolInfoImp = method_getImplementation(class_getClassMethod(self, @selector(poolInfo)));
		return object;
	}
	else
	{
		// recycle element, update poolInfo
		TQPooledObject *object = poolInfo->lastElement;
		poolInfo->lastElement = object->mPoolPredecessor;

		// Subclasses should reset necessary properties when reinitialized. so disregard the following 3 lines
		// zero out memory. (do not overwrite isa & mPoolPredecessor, thus the offset)
		//unsigned int sizeOfFields = sizeof(Class) + sizeof(TQPooledObject *);
		//memset((char*)(id)object + sizeOfFields, 0, malloc_size(object) - sizeOfFields);
		object->_retainCount = 1;
		return object;
	}
}

- (NSUInteger)retainCount
{
	return _retainCount;
}

- (id)retain
{
	__sync_add_and_fetch(&_retainCount, 1);
	return self;
}

- (oneway void)release
{
	if (!__sync_sub_and_fetch(&_retainCount, 1))
	{
		TQPoolInfo *poolInfo = _poolInfoImp(self->isa, @selector(poolInfo));
		self->mPoolPredecessor = poolInfo->lastElement;
		poolInfo->lastElement = self;
	}
}

- (void)purge
{
	// will call 'dealloc' internally --
	// which should not be called directly.
	[super release];
}

+ (int)purgePool
{
	TQPoolInfo *poolInfo = [self poolInfo];
	TQPooledObject *lastElement;

	int count=0;
	while ((lastElement = poolInfo->lastElement))
	{
		++count;
		poolInfo->lastElement = lastElement->mPoolPredecessor;
		[lastElement purge];
	}

	return count;
}

+ (TQPoolInfo *)poolInfo
{
	[NSException raise:NSGenericException format:COMPLAIN_MISSING_IMP, self];
	return 0;
}

@end

#else

@implementation TQPooledObject

+ (TQPoolInfo *)poolInfo
{
	return nil;
}

+ (int)purgePool
{
	return 0;
}

@end


#endif
