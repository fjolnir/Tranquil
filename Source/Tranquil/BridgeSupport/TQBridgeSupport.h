#import <Tranquil/TQObject.h>
#import <Tranquil/CodeGen/TQNodeBlock.h>
#import <Tranquil/BridgeSupport/TQBoxedObject.h>
#import <Tranquil/BridgeSupport/bs.h>

@class TQProgram, TQBridgedFunction, TQBridgedConstant, TQBridgedClassInfo;

@interface TQBridgeSupport : TQObject {
    @public
    bs_parser_t *_parser;
    NSMutableDictionary *_functions, *_classes;
    // String constants & enums (Entities whose values are only defined in headers and not stored in the binary)
    NSMutableDictionary *_literalConstants;
    // Other constants
    NSMutableDictionary *_constants;

}
- (id)loadFramework:(NSString *)aFrameworkPath;

+ (llvm::Type *)llvmTypeFromEncoding:(const char *)aEncoding inProgram:(TQProgram *)aProgram;

// The following accessors return a node if the entity is found, otherwise nil
- (TQNode *)entityNamed:(NSString *)aName;
- (TQBridgedFunction *)functionNamed:(NSString *)aName;
- (TQBridgedConstant *)constantNamed:(NSString *)aName;
- (TQBridgedClassInfo *)classNamed:(NSString *)aName;
@end

@interface TQBridgedClassInfo : NSObject
@property(readwrite, retain) NSString *name;
@property(readwrite, retain) NSDictionary *instanceMethods, *classMethods;
@end

@interface TQBridgedMethodInfo : NSObject
@property(readwrite, retain) NSString *className;
@property(readwrite, assign) SEL selector;
@property(readwrite, retain) NSArray *argTypes;
+ (TQBridgedMethodInfo *)methodWithSelector:(SEL)aSelector className:(NSString *)aKlassName argTypes:(NSArray *)aArgTypes;
@end

@interface TQBridgedConstant : TQNode {
    llvm::Value *_global;
}
@property(readonly) NSString *type, *name;
+ (TQBridgedConstant *)constantWithName:(NSString *)aName type:(NSString *)aType;
@end

@interface TQBridgedFunction : TQNodeBlock
@property(readonly) NSString *returnType, *name;
@property(readonly) NSArray *argumentTypes;

+ (TQBridgedFunction *)functionWithName:(NSString *)aName returnType:(NSString *)aReturn argumentTypes:(NSArray *)aArgumentTypes;
@end
