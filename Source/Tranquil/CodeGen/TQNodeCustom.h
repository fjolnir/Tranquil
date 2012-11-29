#import <Tranquil/CodeGen/TQNode.h>

typedef llvm::Value *(^TQNodeCustomBlock)(TQProgram *, TQNodeBlock *, TQNodeRootBlock *);

@interface TQNodeCustom : TQNode
@property(readwrite, copy) TQNodeCustomBlock block;
+ (TQNodeCustom *)nodeWithBlock:(TQNodeCustomBlock)aBlock;
+ (TQNodeCustom *)nodeReturningValue:(llvm::Value *)aVal;
@end
