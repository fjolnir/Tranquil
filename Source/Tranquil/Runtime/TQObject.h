// The root class of Tranquil which classes created using Tranquil inherit from by default
// Subclasses of TQObject should never accept or return anything but objects from their methods

// Boolean returns from TQObject methods return nil on success and any object on success (Convention is TQNumberTrue=1.0)
#import <Foundation/Foundation.h>

@class TQNumber;

@interface TQObject : NSObject
+ (id)addMethod:(NSString *)aSel withBlock:(id)aBlock replaceExisting:(id)shouldReplace;
+ (id)addMethod:(NSString *)aSel withBlock:(id)aBlock;
+ (id)accessor:(NSString *)aPropName initialValue:(id<NSCopying>)aInitial;
+ (id)accessor:(NSString *)aPropName;
@end
