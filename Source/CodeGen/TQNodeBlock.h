#import "TQNode.h"
#include <llvm/Support/IRBuilder.h>

@class TQNodeArgumentDef;

enum TQBlockFlag_t {
	TQ_BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
	TQ_BLOCK_HAS_CXX_OBJ =       (1 << 26),
	TQ_BLOCK_IS_GLOBAL =         (1 << 28),
	TQ_BLOCK_USE_STRET =         (1 << 29),
	TQ_BLOCK_HAS_SIGNATURE  =    (1 << 30)
};

enum TQBlockFieldFlag_t {
	TQ_BLOCK_FIELD_IS_OBJECT   = 0x03,  // id, NSObject, __attribute__((NSObject)), block, ..
	TQ_BLOCK_FIELD_IS_BLOCK    = 0x07,  // a block variable
	TQ_BLOCK_FIELD_IS_BYREF    = 0x08,  // the on stack structure holding the __block variable
	TQ_BLOCK_FIELD_IS_WEAK     = 0x10,  // declared __weak, only used in byref copy helpers
	TQ_BLOCK_FIELD_IS_ARC      = 0x40,  // field has ARC-specific semantics */
	TQ_BLOCK_BYREF_CALLER      = 128,   // called from __block (byref) copy/dispose support routines
	TQ_BLOCK_BYREF_CURRENT_MAX = 256
};

// A block definition ({ :arg | body })
@interface TQNodeBlock : TQNode {
	llvm::Constant *_blockDescriptor;
	llvm::Type *_literalType;
	NSMutableDictionary *_capturedVariables;
}
@property(readwrite, retain) TQNodeBlock *parent;
@property(readwrite, copy) NSMutableArray *arguments;
@property(readwrite, copy, nonatomic) NSMutableArray *statements;
@property(readwrite, copy) NSMutableDictionary *locals;
@property(readwrite, copy) NSString *name;
@property(readonly) llvm::BasicBlock *basicBlock;
@property(readonly) llvm::Function *function;
@property(readonly) llvm::IRBuilder<> *builder;

// This property is only valid when called from a block's subnode within it's generateCode: method
@property(readonly) llvm::Value *autoreleasePool;

+ (TQNodeBlock *)node;
- (NSString *)signature;
- (BOOL)addArgument:(TQNodeArgumentDef *)aArgument error:(NSError **)aoError;
@end

@interface TQNodeRootBlock : TQNodeBlock
@end
