#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeArgumentDef : TQNode
@property(readwrite, retain) NSString *selectorPart;
@property(readwrite, retain) NSString *name;
@property(readwrite, retain) TQNode *defaultArgument;

+ (TQNodeArgumentDef *)nodeWithName:(NSString *)aName selectorPart:(NSString *)aIdentifier;
- (id)initWithName:(NSString *)aName selectorPart:(NSString *)aIdentifier;
@end
