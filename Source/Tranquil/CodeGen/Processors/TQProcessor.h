#import <Foundation/Foundation.h>

@class TQNode;

@interface TQProcessor : NSObject
+ (NSArray *)allProcessors;
+ (void)registerProcessor:(TQProcessor *)aProcessor;

+ (TQNode *)processNode:(TQNode *)aNode withTrace:(NSArray *)aTrace;
@end
