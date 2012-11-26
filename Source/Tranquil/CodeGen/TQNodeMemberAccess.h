#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeMemberAccess : TQNode
@property(readwrite, copy) NSString *ivarName;
+ (TQNodeMemberAccess *)nodeWithName:(NSString *)aKey;
- (id)initWithName:(NSString *)aKey;
@end
