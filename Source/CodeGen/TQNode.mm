#import "TQNode.h"

using namespace llvm;

NSString * const kTQSyntaxErrorDomain = @"org.tranquil.syntax";
NSString * const kTQGenericErrorDomain = @"org.tranquil.generic";

@implementation TQNode
+ (TQNode *)node
{
	return [[[self alloc] init] autorelease];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
	NSLog(@"Code generation has not been implemented for %@.", [self class]);
	return NULL;
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
	NSLog(@"Node reference check has not been implemented for %@.", [self class]);
	return nil;
}
@end

@implementation NSArray (TQReferencesNode)
- (TQNode *)tq_referencesNode:(TQNode *)aNode
{
	TQNode *ref;
	for(TQNode *n in self) {
		ref = [n referencesNode:aNode];
		if(ref)
			return ref;
	}
	return nil;
}
@end
