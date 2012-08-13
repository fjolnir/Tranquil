#import <Tranquil/CodeGen/TQNode.h>

// A message to an object (object message: argument.)
@interface TQNodeMessage : TQNode
@property(readwrite, retain) TQNode *receiver;
@property(readwrite) llvm::Value *receiverLLVMValue; // If this is set, the receiver node is ignored
@property(readwrite, copy) NSMutableArray *arguments, *cascadedMessages;
+ (TQNodeMessage *)nodeWithReceiver:(TQNode *)aNode;
- (id)initWithReceiver:(TQNode *)aNode;

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock
                         withArguments:(std::vector<llvm::Value*>)aArgs error:(NSError **)aoErr;
@end
