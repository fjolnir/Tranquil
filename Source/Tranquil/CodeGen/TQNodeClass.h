#import <Tranquil/CodeGen/TQNode.h>

// A class definition (class Name < SuperClass\n methods\n end)
@interface TQNodeClass : TQNode
@property(readwrite, retain) OFString *name;
@property(readwrite, retain) OFString *superClassName;
@property(readwrite, copy) OFMutableArray *classMethods;
@property(readwrite, copy) OFMutableArray *instanceMethods;
@property(readwrite, copy) OFMutableArray *onloadMessages;
@property(readwrite, assign) llvm::Value *classPtr;
+ (TQNodeClass *)nodeWithName:(OFString *)aName;
- (id)initWithName:(OFString *)aName;
@end
