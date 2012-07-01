#import <Foundation/Foundation.h>

// Implements an object pool that allocates objects in batches of 32.
// And recycles objects when the retain count reaches 0
// Borrowed from Mulle kybernetiK
// TODO: Make this thread safe.

typedef struct
{
   void *currentBunch; // need this be volatile ?
} BunchInfo;

@interface TQPooledObject : NSObject
{
   unsigned int _retainCountMinusOne;
}
+ (volatile BunchInfo *) bunchInfo;
@end

