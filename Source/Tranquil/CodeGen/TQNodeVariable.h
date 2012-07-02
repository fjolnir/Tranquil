#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeVariable : TQNode
@property(readwrite, retain) NSString *name;
@property(readwrite, assign) llvm::Value *alloca, *forwarding;

+ (TQNodeVariable *)nodeWithName:(NSString *)aName;
- (id)initWithName:(NSString *)aName;

 - (llvm::Value *)createStorageInProgram:(TQProgram *)aProgram
                                   block:(TQNodeBlock *)aBlock
                                   error:(NSError **)aoError;
- (llvm::Type *)captureStructTypeInProgram:(TQProgram *)aProgram;
@end

@interface TQNodeSelf : TQNodeVariable
@end

@interface TQNodeSuper : TQNodeVariable {
   llvm::Type *_structType;
}
@end
