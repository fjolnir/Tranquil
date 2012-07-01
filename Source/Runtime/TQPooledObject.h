// Borrowed from the Sparrow project
#import <Foundation/Foundation.h>

@class TQPooledObject;

typedef struct _TQPoolInfo {
    Class poolClass;
    TQPooledObject *lastElement;
} TQPoolInfo;

// TQPooledObject is an alternative root class whose subclasses are recycled
// rather than deallocated (until the pool overflows that is)

// A subclass needs to implement:
// static TQPoolInfo poolInfo;
// static IMP superAllocImp = NULL;
// + (void)load {
//     superAllocImp = method_getImplementation(class_getClassMethod(self,  @selector(allocWithPoolInfo:)));
// }
// + (TQPoolInfo *) poolInfo
// {
//     return poolInfo;
// }
// + (id)allocWithZone:(NSZone *)zone
// {
//     return superAllocImp(self, @selector(allocWithPoolInfo:), &poolInfo);
// }

#ifndef DISABLE_OBJECT_POOL

@interface TQPooledObject : NSObject
{
	TQPooledObject *mPoolPredecessor;
	NSUInteger _retainCount;
	IMP _poolInfoImp;
}
	
+ (TQPoolInfo *)poolInfo;
+ (int)purgePool;
@end

#else

@interface TQPooledObject : NSObject
+ (TQPoolInfo *)poolInfo;
+ (int)purgePool;
@end

#endif
