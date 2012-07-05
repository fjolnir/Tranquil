// Note: TQNumber is not safe to subclass. It makes certain assumptions for the sake of performance

#import <Foundation/Foundation.h>
#import <Tranquil/TQObject.h>
#import <Tranquil/TQBatching.h>

@class TQRange;

@interface TQNumber : TQObject {
    @public
    double _value;
    TQ_BATCH_IVARS
}
@property(readonly) double value;

+ (TQNumber *)numberWithDouble:(double)aValue;

- (TQNumber *)add:(TQNumber *)b;
- (TQNumber *)subtract:(TQNumber *)b;
- (TQNumber *)negate;
- (TQNumber *)multiply:(TQNumber *)b;
- (TQNumber *)divideBy:(TQNumber *)b;

- (id)times:(id (^)())block;

@end
