#import "TQPooledObject.h"
#import <malloc/malloc.h>
#import <objc/runtime.h>

#define COMPLAIN_MISSING_SUPPORT @"Class %@ needs this code:\n\
static TQPoolInfo poolInfo;\n\
static IMP superAllocImp = NULL;\n\
+ (void)load {\n\
    superAllocImp = method_getImplementation(class_getClassMethod(self, @selector(allocWithPoolInfo:)));\n\
}\n\
+ (TQPoolInfo *) poolInfo\n\
{\n\
  return poolInfo;\n\
}\n\
+ (id)allocWithZone:(NSZone *)zone\n\
{\n\
    return superAllocImp(self, @selector(allocWithPoolInfo:), &poolInfo);\n\
}"

#ifndef DISABLE_OBJECT_POOL

@implementation TQPooledObject

+ (id)allocWithZone:(NSZone *)zone
{
    // Implemented by subclasses
	[NSException raise:NSGenericException format:COMPLAIN_MISSING_SUPPORT, self];
	return nil;
}

+ (TQPoolInfo *)poolInfo
{
    // Implemented by subclasses
	[NSException raise:NSGenericException format:COMPLAIN_MISSING_SUPPORT, self];
	return 0;
}

+ (id)allocWithPoolInfo:(TQPoolInfo *)poolInfo
{
	if(!poolInfo->poolClass)
	{
        // First use of the pool
		poolInfo->poolClass = self;
		poolInfo->lastElement = NULL;
	}
	else if(poolInfo->poolClass != self)
        [NSException raise:NSGenericException
                    format:COMPLAIN_MISSING_SUPPORT, self];

	if(!poolInfo->lastElement)
	{
		// Pool is empty => allocate new object
		TQPooledObject *object = NSAllocateObject(self, 0, NULL);
		object->_retainCount = 1;
		object->_poolInfoImp = method_getImplementation(class_getClassMethod(self, @selector(poolInfo)));
		return object;
	}
	else
	{
		// Recycle element, update poolInfo
		TQPooledObject *object = poolInfo->lastElement;
		poolInfo->lastElement = object->mPoolPredecessor;

		// Subclasses should reset necessary properties when reinitialized.
        // So we do NOT zero out the object because it is quite expensive.
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
	if(!__sync_sub_and_fetch(&_retainCount, 1))
	{
		TQPoolInfo *poolInfo = (TQPoolInfo *)_poolInfoImp(self->isa, @selector(poolInfo));
		self->mPoolPredecessor = poolInfo->lastElement;
		poolInfo->lastElement = self;
	}
}

- (void)purge
{
	// Actually deallocates the object
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
