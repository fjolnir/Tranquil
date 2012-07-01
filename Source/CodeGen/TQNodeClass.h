#import "TQNode.h"

// A class definition (class Name < SuperClass\n methods\n end)
@interface TQNodeClass : TQNode
@property(readwrite, retain) NSString *name;
@property(readwrite, retain) NSString *superClassName;
@property(readwrite, copy) NSMutableArray *classMethods;
@property(readwrite, copy) NSMutableArray *instanceMethods;
@property(readwrite, assign) llvm::Value *classPtr;
+ (TQNodeClass *)nodeWithName:(NSString *)aName;
- (id)initWithName:(NSString *)aName;
@end
