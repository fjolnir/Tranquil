#import <Tranquil/TQObject.h>
#import <Tranquil/CodeGen/TQNodeBlock.h>
#import <Tranquil/BridgeSupport/TQBoxedObject.h>
#import <clang-c/Index.h>

@class TQProgram, TQBridgedFunction, TQBridgedConstant, TQBridgedClassInfo;

@interface TQHeaderParser : NSObject {
    @public
    NSMutableDictionary *_functions, *_classes;
    // String constants & enums (Entities whose values are only defined in headers and not stored in the binary)
    NSMutableDictionary *_literalConstants;
    // Other constants
    NSMutableDictionary *_constants;

    // Protocols (Only used internally)
    NSMutableDictionary *_protocols;
    // Typedef encodings (Only used internally)
    NSMutableDictionary *_typedefs;

    TQBridgedClassInfo *_currentClass;
    CXIndex _index;
}
- (id)parseHeader:(NSString *)aPath;

// The following accessors return a node if the entity is found, otherwise nil
- (TQNode *)entityNamed:(NSString *)aName;
- (TQBridgedFunction *)functionNamed:(NSString *)aName;
- (TQBridgedConstant *)constantNamed:(NSString *)aName;
- (TQBridgedClassInfo *)classNamed:(NSString *)aName;
@end

@interface TQBridgedClassInfo : NSObject
@property(readwrite, retain) NSString *name;
@property(readwrite, retain) TQBridgedClassInfo *superclass;
// Keyed by selector, values are type encoding strings
@property(readwrite, retain) NSMutableDictionary *instanceMethods, *classMethods;

- (NSString *)typeForInstanceMethod:(NSString *)aSelector;
- (NSString *)typeForClassMethod:(NSString *)aSelector;
@end

@interface TQBridgedConstant : TQNode {
    llvm::Value *_global;
}
@property(readwrite, retain) NSString *name;
@property(readwrite) const char *encoding;
+ (TQBridgedConstant *)constantWithName:(NSString *)aName encoding:(const char *)aEncoding;
@end

@interface TQBridgedFunction : TQNodeBlock
@property(readwrite, retain) NSString *name;
@property(readwrite) const char *encoding;
+ (TQBridgedFunction *)functionWithName:(NSString *)aName encoding:(const char *)aEncoding;
@end
