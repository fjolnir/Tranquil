// Note: TQNumber is not safe to subclass. It makes certain assumptions for the sake of performance

#import <Foundation/Foundation.h>
#import <Tranquil/TQObject.h>
#import <Tranquil/TQPooling.h>

@interface TQNumber : TQObject {
    @public
    double _value;
    TQ_POOL_IVARS
}
@property(readonly) double doubleValue;

+ (TQNumber *)numberWithDouble:(double)aValue;

- (TQNumber *)add:(TQNumber *)b;
- (TQNumber *)subtract:(TQNumber *)b;
- (TQNumber *)negate;
- (TQNumber *)multiply:(TQNumber *)b;
- (TQNumber *)divideBy:(TQNumber *)b;

TQ_POOL_INTERFACE
@end

extern TQNumber *TQNumberTrue, *TQNumberFalse;

