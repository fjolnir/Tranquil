#import <Tranquil/Shared/TQDebug.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <assert.h>

// the size needed for the batch, with proper alignment for objects
#define ALIGNMENT           8
#define OBJECTS_PER_BUNCH   64
#define BatchSize           ((sizeof(TQBatch) + (ALIGNMENT - 1)) & ~(ALIGNMENT - 1))
#define PoolSize            128

typedef struct
{
    long    _instance_size;
    int32_t _freed;
    int32_t _allocated;
    int32_t _reserved;
} TQBatch;

typedef struct
{
    unsigned long poolSize;
    uintptr_t low, high;
    TQBatch   *currentBatch;
    TQBatch   **batches;
} TQBatchPool;

static inline TQBatch *TQNewObjectBatch(TQBatchPool *pool, long batchInstanceSize)
{
    unsigned long     len;
    unsigned long  size;
    TQBatch        *batch;

    // Empty/Full pool => allocate new batch
    if(pool->low == pool->high || ((pool->high + 1) % pool->poolSize) == pool->low) {
        batchInstanceSize = (batchInstanceSize + (ALIGNMENT - 1)) & ~(ALIGNMENT - 1);
        size = batchInstanceSize + sizeof(int);

        len = size * OBJECTS_PER_BUNCH + BatchSize;
        if(!(batch = (TQBatch *)calloc(1, len))){
            TQLog(@"Failed to allocate object. Out of memory?");
            return nil;
        }
        batch->_instance_size = batchInstanceSize;
    } else {
        // Otherwise we recycle an existing batch
        batch = pool->batches[pool->low];
        pool->low = (pool->low + 1) % pool->poolSize;
    }
    return batch;
}

static inline void TQFreeObjectBatch(TQBatchPool *pool, TQBatch *batch)
{
    unsigned int next = (pool->high + 1) % pool->poolSize;
    if(next == pool->low) // Full?
        free(batch);
    else {
        batch->_freed = 0;
        batch->_allocated = 0;
        pool->batches[pool->high] = batch;
        pool->high = next;
        if(pool->currentBatch == batch)
            pool->currentBatch = pool->batches[next];
    }
}

static inline BOOL TQSizeFitsObjectBatch(TQBatch *p, long size)
{
    // We can't deal with subclasses larger than what we first allocated
    return p && size <= p->_instance_size;
}

static inline BOOL TQBatchIsExhausted(TQBatch *p)
{
    return p->_allocated == OBJECTS_PER_BUNCH;
}


#define TQ_BATCH_IVARS \
    /* The batch the object is in */\
    TQBatch *_batch; \
    /* It's minus one so we don't have to initialize it to 1 */\
    long _retainCountMinusOne;

#define TQ_BATCH_IMPL(Klass) \
static TQBatchPool _BatchPool; \
\
static inline Klass *TQBatchAlloc##Klass(Class self) \
{ \
    Klass       *obj   = nil; \
    TQBatchPool *pool  = &_BatchPool; \
\
    if(!pool->batches) { \
        pool->poolSize = PoolSize; \
        pool->batches  = (TQBatch **)malloc(sizeof(void*) * pool->poolSize); \
    } \
\
    /* First time? => Allocate & initialize a new batch */\
    size_t instanceSize = class_getInstanceSize(self); \
    if(!pool->currentBatch) \
        pool->currentBatch = TQNewObjectBatch(pool, instanceSize); \
\
    TQBatch *batch = pool->currentBatch; \
    if(TQSizeFitsObjectBatch(pool->currentBatch, instanceSize)) \
    { \
        /* Grab an object from the current batch */\
        /* and place isa pointer there */\
        unsigned long offset; \
\
        offset      = BatchSize + batch->_instance_size * batch->_allocated; \
        obj         = (id)((char *)batch + offset); \
        obj->_batch = batch; \
        obj->_retainCountMinusOne = 0; \
\
        batch->_allocated++; \
        *(Class *)obj = self; \
    } \
    assert(obj != nil); \
\
    /* Batch full? => Make a new one for next time */\
    if(TQBatchIsExhausted(batch) && pool->currentBatch == batch) \
        pool->currentBatch = TQNewObjectBatch(pool, instanceSize); \
\
    return obj; \
} \
\
+ (id)alloc                        { return TQBatchAlloc##Klass(self); } \
\
- (id)retain \
{ \
    __sync_add_and_fetch(&_retainCountMinusOne, 1); \
    return self; \
} \
- (void)release \
{ \
    if(__sync_sub_and_fetch(&_retainCountMinusOne, 1) < 0) \
        [self dealloc]; \
}

#define TQ_BATCH_DEALLOC \
    /* Free the entire batch if all the objects in it are unreferenced */\
    if(__sync_add_and_fetch(&_batch->_freed, 1) == OBJECTS_PER_BUNCH) \
        TQFreeObjectBatch(&_BatchPool, _batch); \
    else if(NO) [super dealloc]; /* Silence compiler warning about not calling super dealloc */

