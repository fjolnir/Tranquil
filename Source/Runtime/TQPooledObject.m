#import "TQPooledObject.h"
#import <objc/objc.h>
#import <objc/objc-class.h>

//
// The structure at the beginning of
// every Bunch
//
typedef struct {
	long         instance_size_;
	unsigned int freed_;
	unsigned int allocated_; // allocated by "user"
	unsigned int reserved_; // reserved from malloc
} Bunch;

//
// the size needed for the bunch
// with proper alignment for objects
//
#define S_Bunch             ((sizeof( Bunch) + (ALIGNMENT - 1)) & ~(ALIGNMENT - 1))
#define ALIGNMENT           8
#define OBJECTS_PER_MALLOC  32


@implementation TQPooledObject


static Bunch *newBunch( long bunchInstanceSize)
{
	unsigned int  len;
	unsigned int  nBunches;
	unsigned long size;
	Bunch         *p;

	bunchInstanceSize = (bunchInstanceSize + (ALIGNMENT - 1)) & ~(ALIGNMENT - 1);
	size = bunchInstanceSize + sizeof( int);

	nBunches = OBJECTS_PER_MALLOC;
	len = size * nBunches + S_Bunch;
	if( ! (p = (Bunch*)calloc( len, 1)))	// calloc, for compatibility
		return( nil);

	p->instance_size_ = bunchInstanceSize;
	return( p);
}


static inline void	freeBunch( Bunch *p)
{
	free( p);
}


static inline BOOL	canBunchHandleSize( Bunch *p, size_t size)
{
	//
	// We can't deal with subclasses, that are larger then what we
	// first allocated.
	//
	return( p && size <= p->instance_size_);
}


static inline unsigned int nObjectsABunch( Bunch *p)
{
	return( OBJECTS_PER_MALLOC);
}


static inline BOOL isBunchExhausted( Bunch *p)
{
	return( p->allocated_ == nObjectsABunch( p));
}


static inline id	newTQPooledObject( Bunch *p)
{
	id				 obj;
	unsigned int	offset;

	//
	// Build an object
	// put offset to the bunch structure ahead of the isa pointer.
	//
	offset = S_Bunch + (sizeof( int) + p->instance_size_) * p->allocated_;
	obj	 = (id) ((char *) p + offset);
	unsigned int *temp = (unsigned int *) obj;
	*temp++ = offset + sizeof( int);

	//
	// up the allocation count
	//
	p->allocated_++;

	return( obj);
}


//
// determine Bunch adress from object adress
//
static inline Bunch *bunchForObject( id self)
{
	int offset;
	Bunch *p;

	offset = ((int *) self)[ -1];
	p = (Bunch *) &((char *) self)[-offset];
	return(p);
}


+ (volatile BunchInfo *)bunchInfo
{
	static volatile BunchInfo bunchInfo;

	return( &bunchInfo);
}


/*
##
##	override alloc, dealloc, retain and release
##
*/
static inline TQPooledObject *alloc_object( Class self)
{
	TQPooledObject *obj;
	BOOL flag;
	volatile BunchInfo *p;

	obj = nil;

	p = [self bunchInfo]; // this hurts a little, because we call it every time

	//
	// first time ? malloc and initialize a new bunch
	//
	if( ! p->currentBunch)
		p->currentBunch = newBunch( class_getInstanceSize(self));

	if( canBunchHandleSize((Bunch*)p->currentBunch, class_getInstanceSize(self)))
	{
		//
		// grab an object from the current bunch
		// and place isa pointer there
		//
		obj = newTQPooledObject((Bunch*) p->currentBunch);

		obj->isa = self;
	}

	//
	// bunch full ? then make a new one for next time
	//
	if( isBunchExhausted((Bunch*)p->currentBunch))
		p->currentBunch = newBunch(class_getInstanceSize(self));

	//
	// Failed means, some subclass is calling...
	//
	if( ! obj)
		[NSException raise:NSGenericException
		            format:@"To be able to allocate an instance,\
 your class %@ needs this code:\n\
\n\
+ (volatile BunchInfo *) bunchInfo\n\
{\n\
	static BunchInfo	bunchInfo;\n\
\n\
	return( &bunchInfo);\n\
}\
", self];

	return( obj);
}


+ (id) allocWithZone:(NSZone *) zone
{
	TQPooledObject *obj;

	obj = alloc_object( self);
	return( obj);
}


//
// Only free a bunch, if all objects are
// allocated(!) and freed
//
- (void) dealloc
{
	Bunch *p;

	p = bunchForObject( self);
	if( ++p->freed_ == nObjectsABunch( p))
		freeBunch( p);
}


- (id) retain
{
	++_retainCountMinusOne;
	return( self);
}


- (oneway void) release
{
	if(!_retainCountMinusOne--)
		[self dealloc];
	//NSLog(@"releasing num %d", _retainCountMinusOne);
}

@end
