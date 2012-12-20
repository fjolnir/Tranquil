#ifndef TQ_NO_BIGNUM
#import <Tranquil/Runtime/TQObject.h>
#import <Tranquil/Shared/TQBatching.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <gmp.h>

@class TQNumber;

@interface TQBigNumber : TQObject {
    @protected
    mpf_t _value;
    TQ_BATCH_IVARS
}
@property(readonly) double doubleValue;
@property(readonly) TQNumber *numberValue;

+ (TQBigNumber *)withDouble:(double)aValue;
+ (TQBigNumber *)withNumber:(TQNumber *)aValue;

- (TQBigNumber *)add:(id)b;
- (TQBigNumber *)subtract:(id)b;

- (TQBigNumber *)negate;

- (TQBigNumber *)abs;
- (TQBigNumber *)ceil;
- (TQBigNumber *)floor;

- (TQBigNumber *)multiply:(id)b;

- (TQBigNumber *)divide:(id)b;

- (TQBigNumber *)pow:(id)b;
- (TQBigNumber *)sqrt;
@end
#endif
