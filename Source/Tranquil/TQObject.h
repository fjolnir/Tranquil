// The root class of Tranquil which classes created using Tranquil inherit from by default
// Subclasses of TQObject should never accept or return anything but objects from their methods

// Boolean returns from TQObject methods return nil on success and any object on success (Convention is TQNumberTrue=1.0)
#import <Foundation/Foundation.h>

@interface TQObject : NSObject

@end
