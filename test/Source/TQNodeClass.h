#import "TQNode.h"

// A class definition (class Name < SuperClass\n methods\n end)
@interface TQNodeClass : TQNode
@property(readwrite, retain) NSString *name;
@property(readwrite, retain) NSString *superClassName;
@property(readwrite, copy) NSMutableArray *classMethods;
@property(readwrite, copy) NSMutableArray *instanceMethods;
+ (TQNodeClass *)nodeWithName:(NSString *)aName superClass:(NSString *)aSuperClass error:(NSError **)aoError;
- (id)initWithName:(NSString *)aName superClass:(NSString *)aSuperClass error:(NSError **)aoError;
@end
