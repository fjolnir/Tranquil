#import "TQNode.h"

// A message to an object (object message: argument.)
@interface TQNodeMessage : TQNode
@property(readwrite, retain) TQNode *receiver;
@property(readwrite, copy) NSMutableArray *arguments;
+ (TQNodeMessage *)nodeWithReceiver:(TQNode *)aNode;
- (id)initWithReceiver:(TQNode *)aNode;

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock
                         withArguments:(std::vector<llvm::Value*>)aArgs error:(NSError **)aoErr;
@end
