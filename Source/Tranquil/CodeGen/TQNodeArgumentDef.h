#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeArgumentDef : TQNode {
	@protected
		NSString *_name;
}
@property(readwrite, retain) NSString *name;
@property(readwrite, retain) TQNode *defaultArgument;
@property(readwrite, assign) BOOL unretained;

+ (TQNodeArgumentDef *)nodeWithName:(NSString *)aName;
@end

@interface TQNodeMethodArgumentDef : TQNodeArgumentDef
@property(readwrite, retain) NSString *selectorPart;

+ (TQNodeMethodArgumentDef *)nodeWithName:(NSString *)aName selectorPart:(NSString *)aSelectorPart;
@end
