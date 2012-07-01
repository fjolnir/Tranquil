// Note: TQNumber is not safe to subclass. It makes certain assumptions for the sake of performance

#import <Foundation/Foundation.h>

@interface TQNumber : NSObject {
    @public
    double _value;
    @private
    TQNumber *_poolPredecessor;
    NSUInteger _retainCount;
}
@property(readonly) double doubleValue;

+ (TQNumber *)numberWithDouble:(double)aValue;

- (TQNumber *)add:(TQNumber *)b;
- (TQNumber *)subtract:(TQNumber *)b;
- (TQNumber *)negate;
- (TQNumber *)multiply:(TQNumber *)b;
- (TQNumber *)divideBy:(TQNumber *)b;

+ (int)purgeCache;
@end

extern TQNumber *TQNumberTrue, *TQNumberFalse;

