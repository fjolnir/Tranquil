#import <Foundation/Foundation.h>
#import <Tranquil/Shared/TQDebug.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <libkern/OSAtomic.h>

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
    NSUInteger poolSize;
    uintptr_t low, high;
    TQBatch   *currentBatch;
    TQBatch   **batches;
    OSSpinLock spinLock;
} TQBatchPool;

static inline TQBatch *TQNewObjectBatch(TQBatchPool *pool, long batchInstanceSize)
{
    NSUInteger     len;
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

static inline void TQRecycleObjectBatch(TQBatchPool *pool, TQBatch *batch)
{
    unsigned int next = (pool->high + 1) % pool->poolSize;
    if(next == pool->low) // Full?
        free(batch);
    else {
        batch->_freed = 0;
        batch->_allocated = 0;
        pool->batches[pool->high] = batch;
        pool->high = next;
        __sync_val_compare_and_swap(&pool->currentBatch, batch, pool->batches[next]);
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

#define TQ_BATCH_IVARS                                                                         \
    /* The batch the object is in */                                                           \
    TQBatch *_batch;                                                                           \
    /* It's minus one so we don't have to initialize it to 1 */                                \
    NSInteger _retainCountMinusOne;

#define TQ_BATCH_IMPL(Klass)                                                                   \
static TQBatchPool _BatchPool;                                                                 \
                                                                                               \
static inline Klass *TQBatchAlloc##Klass(Class self)                                           \
{                                                                                              \
    size_t instanceSize = class_getInstanceSize(self);                                         \
    OSSpinLockLock(&_BatchPool.spinLock);                                                      \
    if(__builtin_expect(!_BatchPool.batches, 0)) {                                             \
        _BatchPool.poolSize = PoolSize;                                                        \
        _BatchPool.batches  = (TQBatch **)malloc(sizeof(void*) * _BatchPool.poolSize);         \
        _BatchPool.currentBatch = TQNewObjectBatch(&_BatchPool, instanceSize);                 \
    }                                                                                          \
                                                                                               \
    Klass *obj = nil;                                                                          \
    TQBatch *batch = _BatchPool.currentBatch;                                                  \
    if(__builtin_expect(TQSizeFitsObjectBatch(_BatchPool.currentBatch, instanceSize), 1))      \
    {                                                                                          \
        /* Grab an object from the current batch */                                            \
        /* and place isa pointer there */                                                      \
        NSUInteger offset;                                                                     \
        offset      = BatchSize + batch->_instance_size * batch->_allocated;                   \
        obj         = (id)((char *)batch + offset);                                            \
        obj->_batch = batch;                                                                   \
        obj->_retainCountMinusOne = 0;                                                         \
                                                                                               \
        batch->_allocated++;                                                                   \
        *(Class *)obj = self;                                                                  \
    } else {                                                                                   \
        TQAssert(NO, @"Unable to get %@ from batch", self);                                    \
    }                                                                                          \
                                                                                               \
    /* Batch full? => Make a new one for next time */                                          \
    if(TQBatchIsExhausted(batch) && _BatchPool.currentBatch == batch)                          \
        _BatchPool.currentBatch = TQNewObjectBatch(&_BatchPool, instanceSize);                 \
                                                                                               \
    OSSpinLockUnlock(&_BatchPool.spinLock);                                                    \
    return obj;                                                                                \
}                                                                                              \
                                                                                               \
+ (id)allocWithZone:(NSZone *)zone { return TQBatchAlloc##Klass(self); }                       \
+ (id)alloc                        { return TQBatchAlloc##Klass(self); }                       \
                                                                                               \
- (id)retain                                                                                   \
{                                                                                              \
    __sync_add_and_fetch(&_retainCountMinusOne, 1);                                            \
    return self;                                                                               \
}                                                                                              \
- (oneway void)release                                                                         \
{                                                                                              \
    if(__builtin_expect(__sync_sub_and_fetch(&_retainCountMinusOne, 1) < 0, 0))                \
        [self dealloc];                                                                        \
}

#define TQ_BATCH_DEALLOC                                                                       \
    /* Recycle the entire batch if all the objects in it are unreferenced */                   \
    if(__sync_add_and_fetch(&_batch->_freed, 1) == OBJECTS_PER_BUNCH) {                        \
        OSSpinLockLock(&_BatchPool.spinLock);                                                  \
        TQRecycleObjectBatch(&_BatchPool, _batch);                                             \
        OSSpinLockUnlock(&_BatchPool.spinLock);                                                \
    }                                                                                          \
    else if(NO) [super dealloc]; /* Silence compiler warning about not calling super dealloc */
