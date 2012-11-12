#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeLock : TQNode
@property(readwrite, retain) TQNode *condition;
@property(readwrite, retain) OFMutableArray *statements;

+ (TQNodeLock *)nodeWithCondition:(TQNode *)aCond;
@end
