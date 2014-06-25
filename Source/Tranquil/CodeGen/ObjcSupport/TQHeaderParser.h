#import <Tranquil/Runtime/TQObject.h>
#import <Tranquil/CodeGen/TQNodeBlock.h>
#import <Tranquil/RunTime/TQBoxedObject.h>
#import <clang-c/Index.h>

@class TQProgram, TQBridgedFunction, TQBridgedConstant, TQBridgedClassInfo;

@interface TQHeaderParser : TQObject {
    @public
    NSMutableDictionary *_functions, *_classes;
    // String constants & enums (Entities whose values are only defined in headers and not stored in the binary)
    NSMutableDictionary *_literalConstants;
    // Other constants
    NSMutableDictionary *_constants;

    // Protocols
    NSMutableDictionary *_protocols;

    CXIndex _index;
}
- (id)parseHeader:(NSString *)aPath;
- (id)parseTQPCH:(NSString *)aPath;
- (id)parsePCH:(NSString *)aPath;

// The following accessors return a node if the entity is found, otherwise nil
- (TQNode *)entityNamed:(NSString *)aName;
- (TQBridgedFunction *)functionNamed:(NSString *)aName;
- (TQBridgedConstant *)constantNamed:(NSString *)aName;
- (TQBridgedClassInfo *)classNamed:(NSString *)aName;
- (NSString *)classMethodTypeFromProtocols:(NSString *)aSelector;
- (NSString *)instanceMethodTypeFromProtocols:(NSString *)aSelector;
@end

@interface TQBridgedClassInfo : NSObject <NSCoding> {
    NSKeyedArchiver *_decoder;
}
@property(readwrite, retain) NSString *name;
@property(readwrite, retain) TQBridgedClassInfo *superclass;
// Keyed by selector, values are type encoding strings
@property(nonatomic, readwrite, retain) NSMutableDictionary *instanceMethods, *classMethods;

- (NSString *)typeForInstanceMethod:(NSString *)aSelector;
- (NSString *)typeForClassMethod:(NSString *)aSelector;
@end

@interface TQBridgedConstant : TQNode <NSCoding> {
    llvm::Value *_global;
}
@property(readwrite, retain) NSString *name;
@property(readonly) char *encoding;
+ (TQBridgedConstant *)constantWithName:(NSString *)aName encoding:(const char *)aEncoding;
@end

@interface TQBridgedFunction : TQNodeBlock <NSCoding>
@property(readwrite, retain) NSString *name;
@property(readonly) char *encoding;
+ (TQBridgedFunction *)functionWithName:(NSString *)aName encoding:(const char *)aEncoding;
@end
