#import "TQNodeIdentifier.h"

using namespace llvm;

@implementation TQNodeIdentifier

+ (TQNodeIdentifier *)nodeWithCString:(const char *)aStr { return (TQNodeIdentifier *)[super nodeWithCString:aStr]; }

- (NSString *)description
{
	return [NSString stringWithFormat:@"<ident@ %@>", [self value]];
}

@end
