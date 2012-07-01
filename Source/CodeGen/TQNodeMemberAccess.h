#import "TQNode.h"

// Object member access (object#member)
@interface TQNodeMemberAccess : TQNode
@property(readwrite, retain) TQNode *receiver;
@property(readwrite, copy) NSString *property;
+ (TQNodeMemberAccess *)nodeWithReceiver:(TQNode *)aReceiver property:(NSString *)aKey;
- (id)initWithReceiver:(TQNode *)aReceiver property:(NSString *)aKey;
- (llvm::Value *)store:(llvm::Value *)aValue
             inProgram:(TQProgram *)aProgram
                 block:(TQNodeBlock *)aBlock
                 error:(NSError **)aoError;
@end
