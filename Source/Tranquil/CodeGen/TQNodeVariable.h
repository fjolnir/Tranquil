#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeVariable : TQNode
@property(readwrite, retain) NSString *name;
@property(readonly) BOOL isGlobal;
// Anonymous variables are invisible from tranquil, and are captured by value when their
// capturing block is copied
@property(readwrite, nonatomic) BOOL isAnonymous, shadows;
@property(readwrite, assign) llvm::Value *alloca, *forwarding;

+ (TQNodeVariable *)node;
+ (TQNodeVariable *)tempVar;
+ (TQNodeVariable *)nodeWithName:(NSString *)aName;
- (id)initWithName:(NSString *)aName;

 - (llvm::Value *)createStorageInProgram:(TQProgram *)aProgram
                                   block:(TQNodeBlock *)aBlock
                                    root:(TQNodeRootBlock *)aRoot
                                   error:(NSError **)aoErr;
+ (llvm::Type *)captureStructTypeInProgram:(TQProgram *)aProgram;
+ (llvm::Type *)valueTypeInProgram:(TQProgram *)aProgram;
+ (BOOL)valueIsObject; // Necessary because an i8Ptr is not necessarily an object

- (llvm::Value *)store:(llvm::Value *)aValue
              retained:(BOOL)aRetain
             inProgram:(TQProgram *)aProgram
                 block:(TQNodeBlock *)aBlock
                  root:(TQNodeRootBlock *)aRoot
                 error:(NSError **)aoErr;

- (void)generateRetainInProgram:(TQProgram *)aProgram
                          block:(TQNodeBlock *)aBlock
                           root:(TQNodeRootBlock *)aRoot;
- (void)generateReleaseInProgram:(TQProgram *)aProgram
                           block:(TQNodeBlock *)aBlock
                            root:(TQNodeRootBlock *)aRoot;
@end

@interface TQNodeSelf : TQNodeVariable
@end

@interface TQNodeSuper : TQNodeVariable {
   llvm::Type *_structType;
}
@end

@interface TQNodeIntVariable : TQNodeVariable
+ (TQNodeIntVariable *)tempVar;
+ (TQNodeIntVariable *)node;
@end

@interface TQNodeLongVariable : TQNodeIntVariable
+ (TQNodeLongVariable *)tempVar;
+ (TQNodeLongVariable *)node;
@end

@interface TQNodePointerVariable : TQNodeIntVariable
+ (TQNodePointerVariable *)tempVar;
+ (TQNodePointerVariable *)node;
@end
