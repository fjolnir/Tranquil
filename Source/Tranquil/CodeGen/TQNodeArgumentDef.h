#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeArgumentDef : TQNode {
	@protected
		OFString *_name;
}
@property(readwrite, retain) OFString *name;
@property(readwrite, retain) TQNode *defaultArgument;
@property(readwrite, assign) BOOL unretained;

+ (TQNodeArgumentDef *)nodeWithName:(OFString *)aName;
@end

@interface TQNodeMethodArgumentDef : TQNodeArgumentDef
@property(readwrite, retain) OFString *selectorPart;

+ (TQNodeMethodArgumentDef *)nodeWithName:(OFString *)aName selectorPart:(OFString *)aSelectorPart;
@end
