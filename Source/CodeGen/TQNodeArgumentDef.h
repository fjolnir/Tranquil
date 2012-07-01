#import "TQNode.h"

@interface TQNodeArgumentDef : TQNode
@property(readwrite, retain) NSString *identifier;
@property(readwrite, retain) NSString *localName;

+ (TQNodeArgumentDef *)nodeWithLocalName:(NSString *)aName identifier:(NSString *)aIdentifier;
- (id)initWithLocalName:(NSString *)aName identifier:(NSString *)aIdentifier;
@end
