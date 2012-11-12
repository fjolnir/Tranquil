#import <Tranquil/CodeGen/TQNode.h>

// Object member access (object#member)
@interface TQNodeMemberAccess : TQNode
@property(readwrite, retain) TQNode *receiver;
@property(readwrite, copy) OFString *property;
+ (TQNodeMemberAccess *)nodeWithReceiver:(TQNode *)aReceiver property:(OFString *)aKey;
- (id)initWithReceiver:(TQNode *)aReceiver property:(OFString *)aKey;
@end
