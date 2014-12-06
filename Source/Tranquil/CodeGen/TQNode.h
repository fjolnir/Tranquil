#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/IR/Constant.h>
#include <llvm/IR/GlobalVariable.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/CallingConv.h>
#include <llvm/IR/BasicBlock.h>
#undef verify // Conflicts with a function name in LLVM
#include <llvm/IR/Instructions.h>
#include <llvm/IR/InlineAsm.h>
#include <llvm/Support/FormattedStream.h>
#include <llvm/Support/MathExtras.h>
#include <llvm/Pass.h>
#include <llvm/IR/Module.h>
#include <llvm/ADT/SmallVector.h>
#include <llvm/IR/Verifier.h>
#include <llvm/IR/IRPrintingPasses.h>
#include <llvm/IR/TypeBuilder.h>
#include <llvm/ExecutionEngine/ExecutionEngine.h>
#include <llvm/ExecutionEngine/GenericValue.h>
#include <llvm/ExecutionEngine/JIT.h>
#include <llvm/Support/TargetSelect.h>
#import <Foundation/Foundation.h>
#import <Tranquil/CodeGen/TQProgram+Internal.h>


@class TQNode, TQNodeBlock, TQNodeRootBlock, TQProgram;

typedef void (^TQNodeIteratorBlock)(TQNode *aNode);

@interface TQNode : NSObject
@property(readwrite, nonatomic) NSUInteger lineNumber; // Default: NSNotFound

+ (TQNode *)node;
- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr;
- (llvm::Value *)store:(llvm::Value *)aValue
             inProgram:(TQProgram *)aProgram
                 block:(TQNodeBlock *)aBlock
                  root:(TQNodeRootBlock *)aRoot
                 error:(NSError **)aoErr;
// Checks if this node references a node equal to aNode and returns it if it does
- (TQNode *)referencesNode:(TQNode *)aNode;
- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock;

- (BOOL)insertChildNode:(TQNode *)aNodeToInsert before:(TQNode *)aNodeToShift;
- (BOOL)insertChildNode:(TQNode *)aNodeToInsert after:(TQNode *)aExistingNode;
- (BOOL)replaceChildNodesIdenticalTo:(TQNode *)aNodeToReplace with:(TQNode *)aNodeToInsert;
- (NSString *)toString;
@end

@interface NSArray (TQReferencesNode)
// Checks if any node in an array of nodes references aNode
- (TQNode *)tq_referencesNode:(TQNode *)aNode;
@end
