#import "TQPooledObject.h"
#import <malloc/malloc.h>

#define COMPLAIN_MISSING_IMP @"Class %@ needs this code:\n\
+ (TQPoolInfo *) poolInfo\n\
{\n\
  static TQPoolInfo *poolInfo = nil;\n\
  if (!poolInfo) poolInfo = [[TQPoolInfo alloc] init];\n\
  return poolInfo;\n\
}"

@implementation TQPoolInfo
// empty
@end

#ifndef DISABLE_MEMORY_POOLING

@implementation TQPooledObject

+ (id)allocWithZone:(NSZone *)zone
{
	TQPoolInfo *poolInfo = [self poolInfo];
	if (!poolInfo->poolClass) // first allocation
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
		object->mRetainCount = 1;
		return object;
	}
	else 
	{
		// recycle element, update poolInfo
		TQPooledObject *object = poolInfo->lastElement;
		poolInfo->lastElement = object->mPoolPredecessor;

		// zero out memory. (do not overwrite isa & mPoolPredecessor, thus the offset)
		unsigned int sizeOfFields = sizeof(Class) + sizeof(TQPooledObject *);
		memset((char*)(id)object + sizeOfFields, 0, malloc_size(object) - sizeOfFields);
		object->mRetainCount = 1;
		return object;
	}
}

- (uint)retainCount
{
	return mRetainCount;
}

- (id)retain
{
	++mRetainCount;
	return self;
}

- (oneway void)release
{
	--mRetainCount;
	
	if (!mRetainCount)
	{
		TQPoolInfo *poolInfo = [isa poolInfo];
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
