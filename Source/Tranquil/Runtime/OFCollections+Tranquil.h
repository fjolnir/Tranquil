#import <ObjFW/ObjFW.h>
#import <Tranquil/Runtime/TQRuntime.h>
#import <Tranquil/Shared/TQBatching.h>

@class TQNumber;

@interface OFDictionary (Tranquil)
+ (OFDictionary *)tq_dictionaryWithObjectsAndKeys:(id)firstObject , ...; // Arguments terminated by TQNothing

- (id)each:(id (^)(id))aBlock;
@end

@interface OFArray (Tranquil)
+ (OFArray *)tq_arrayWithObjects:(id)firstObject , ...;  // Arguments terminated by TQNothing

- (id)each:(id (^)(id))aBlock;
@end

@interface TQPair : TQObject {
    TQ_BATCH_IVARS
}
@property(readwrite, strong) id left, right;
+ (TQPair *)with:(id)left and:(id)right;
- (id)objectAtIndexedSubscript:(unsigned long)idx;
- (id)each:(id (^)(id))aBlock;
@end

