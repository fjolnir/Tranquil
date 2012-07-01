// Borrowed from the Sparrow project
#import <Foundation/Foundation.h>

@class TQPooledObject;

/// Internal Helper class for `TQPooledObject`.
@interface TQPoolInfo : NSObject
{
	@public
		Class poolClass;
		TQPooledObject *lastElement;
}

@end

/** ------------------------------------------------------------------------------------------------

 The TQPooledObject class is an alternative to the base class `NSObject` that manages a pool of
 objects.

 Subclasses of TQPooledObject do not deallocate object instances when the retain counter reaches
 zero. Instead, the objects stay in memory and will be re-used when a new instance of the object
 is requested. That way, object initialization is accelerated. You can release the memory of all
 recycled objects anytime by calling the `purgePool` method.

 Sparrow uses this class for `SPPoint`, `SPRectangle` and `SPMatrix`, as they are created very often
 as helper objects.

 To use memory pooling for another class, you just have to inherit from TQPooledObject and implement
 the following method:

 	+ (TQPoolInfo *)poolInfo
 	{
 			static TQPoolInfo *poolInfo = nil;
 			if (!poolInfo) poolInfo = [[TQPoolInfo alloc] init];
 			return poolInfo;
 	}

 ------------------------------------------------------------------------------------------------- */

#ifndef DISABLE_MEMORY_POOLING

@interface TQPooledObject : NSObject
{
	@private
		TQPooledObject *mPoolPredecessor;
		NSUInteger _retainCount;
		IMP _poolInfoImp;
}
	
/// The pool info structure needed to access the pool. Needs to be implemented in any inheriting class.
+ (TQPoolInfo *)poolInfo;

/// Purge all unused objects.
+ (int)purgePool;

@end

#else

@interface TQPooledObject : NSObject

/// Dummy implementation of TQPooledObject method to simplify switching between NSObject and TQPooledObject.
+ (TQPoolInfo *)poolInfo;

/// Dummy implementation of TQPooledObject method to simplify switching between NSObject and TQPooledObject.
+ (int)purgePool;

@end

#endif
