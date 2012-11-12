#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeImport : TQNode
@property(readwrite, retain) OFString *path;

+ (TQNodeImport *)nodeWithPath:(OFString *)aPath;
@end
