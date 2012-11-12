#import <Tranquil/Runtime/TQObject.h>
#import <Tranquil/CodeGen/TQNodeBlock.h>
#import <Tranquil/RunTime/TQBoxedObject.h>
#import <clang-c/Index.h>

@class TQProgram, TQBridgedFunction, TQBridgedConstant, TQBridgedClassInfo;

@interface TQHeaderParser : TQObject {
    @public
    OFMutableDictionary *_functions, *_classes;
    // String constants & enums (Entities whose values are only defined in headers and not stored in the binary)
    OFMutableDictionary *_literalConstants;
    // Other constants
    OFMutableDictionary *_constants;

    // Protocols (Only used internally)
    OFMutableDictionary *_protocols;

    TQBridgedClassInfo *_currentClass;
    CXIndex _index;
}
- (id)parseHeader:(OFString *)aPath;

// The following accessors return a node if the entity is found, otherwise nil
- (TQNode *)entityNamed:(OFString *)aName;
- (TQBridgedFunction *)functionNamed:(OFString *)aName;
- (TQBridgedConstant *)constantNamed:(OFString *)aName;
- (TQBridgedClassInfo *)classNamed:(OFString *)aName;
@end

@interface TQBridgedClassInfo : TQObject
@property(readwrite, retain) OFString *name;
@property(readwrite, retain) TQBridgedClassInfo *superclass;
// Keyed by selector, values are type encoding strings
@property(readwrite, retain) OFMutableDictionary *instanceMethods, *classMethods;

- (OFString *)typeForInstanceMethod:(OFString *)aSelector;
- (OFString *)typeForClassMethod:(OFString *)aSelector;
@end

@interface TQBridgedConstant : TQNode {
    llvm::Value *_global;
}
@property(readwrite, retain) OFString *name;
@property(readonly) char *encoding;
+ (TQBridgedConstant *)constantWithName:(OFString *)aName encoding:(const char *)aEncoding;
@end

@interface TQBridgedFunction : TQNodeBlock
@property(readwrite, retain) OFString *name;
@property(readonly) char *encoding;
+ (TQBridgedFunction *)functionWithName:(OFString *)aName encoding:(const char *)aEncoding;
@end
