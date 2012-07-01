#import "TQNode.h"

using namespace llvm;

NSString * const kTQSyntaxErrorDomain = @"org.tranquil.syntax";

@implementation TQNode
+ (TQNode *)node
{
	return [[[self alloc] init] autorelease];
}

- (BOOL)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
	NSLog(@"Code generation has not been implemented for %@.", [self class]);
	return NO;
}
@end
