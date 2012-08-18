#import <Tranquil/CodeGen/TQNode.h>

typedef llvm::Value *(^TQNodeCustomBlock)(TQProgram *, TQNodeBlock *, TQNodeRootBlock *);

@interface TQNodeCustom : TQNode
@property(readwrite, retain) TQNodeCustomBlock block;
+ (TQNodeCustom *)nodeWithBlock:(TQNodeCustomBlock)aBlock;
@end
