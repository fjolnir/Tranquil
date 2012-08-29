#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeVariable : TQNode
@property(readwrite, retain) NSString *name;
@property(readonly) BOOL isGlobal;
@property(readwrite, assign) llvm::Value *alloca, *forwarding;

+ (TQNodeVariable *)node;
+ (TQNodeVariable *)nodeWithName:(NSString *)aName;
- (id)initWithName:(NSString *)aName;

 - (llvm::Value *)createStorageInProgram:(TQProgram *)aProgram
                                   block:(TQNodeBlock *)aBlock
                                    root:(TQNodeRootBlock *)aRoot
                                   error:(NSError **)aoErr;
+ (llvm::Type *)captureStructTypeInProgram:(TQProgram *)aProgram;

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
