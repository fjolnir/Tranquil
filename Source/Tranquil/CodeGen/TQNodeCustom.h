#import <Tranquil/CodeGen/TQNode.h>

typedef llvm::Value *(^TQNodeCustomBlock)(TQProgram *, TQNodeBlock *, TQNodeRootBlock *, NSError **);

@interface TQNodeCustom : TQNode
@property(readwrite, copy) TQNodeCustomBlock block;
@property(readwrite, copy) NSArray *references;
+ (TQNodeCustom *)nodeWithBlock:(TQNodeCustomBlock)aBlock;
+ (TQNodeCustom *)nodeReturningValue:(llvm::Value *)aVal;
@end
