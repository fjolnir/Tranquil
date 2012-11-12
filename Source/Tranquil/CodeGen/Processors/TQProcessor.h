#import <Tranquil/Runtime/TQObject.h>

@class TQNode;

@interface TQProcessor : TQObject
+ (OFArray *)allProcessors;
+ (void)registerProcessor:(TQProcessor *)aProcessor;

+ (TQNode *)processNode:(TQNode *)aNode withTrace:(OFArray *)aTrace;
@end
