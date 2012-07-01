#import "TQNode.h"

@interface TQNodeVariable : TQNode
@property(readwrite, retain) NSString *name;
@property(readwrite, assign) llvm::Value *alloca;

+ (TQNodeVariable *)nodeWithName:(NSString *)aName;
- (id)initWithName:(NSString *)aName;

- (llvm::Value *)store:(llvm::Value *)aValue
             inProgram:(TQProgram *)aProgram
                 block:(TQNodeBlock *)aBlock
                 error:(NSError **)aoError;

 - (llvm::Value *)createStorageInProgram:(TQProgram *)aProgram
                                   block:(TQNodeBlock *)aBlock
                                   error:(NSError **)aoError;
- (llvm::Type *)captureStructTypeInProgram:(TQProgram *)aProgram;
@end
