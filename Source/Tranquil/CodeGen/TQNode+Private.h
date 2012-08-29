#import <Tranquil/CodeGen/TQNode.h>

@interface TQNode (Private)
- (void)_attachDebugInformationToInstruction:(llvm::Value *)aInst
                                   inProgram:(TQProgram *)aProgram
                                       block:(TQNodeBlock *)aBlock
                                        root:(TQNodeRootBlock *)aRoot;
@end
