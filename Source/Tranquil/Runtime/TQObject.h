// The root class of Tranquil which classes created using Tranquil inherit from by default
// Subclasses of TQObject should never accept or return anything but objects from their methods

// Boolean returns from TQObject methods return nil on success and any object on success (Convention is TQNumberTrue=1.0)
#import <ObjFW/ObjFW.h>
#import "OFObject+TQAdditions.h"

@class TQNumber;

@interface TQObject : OFObject
+ (id)addMethod:(OFString *)aSel withBlock:(id)aBlock replaceExisting:(id)shouldReplace;
+ (id)addMethod:(OFString *)aSel withBlock:(id)aBlock;
+ (id)accessor:(OFString *)aPropName initialValue:(id<OFCopying>)aInitial;
+ (id)accessor:(OFString *)aPropName;
@end
