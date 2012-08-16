#import <Tranquil/CodeGen/TQNode.h>

@interface TQNodeImport : TQNode
@property(readwrite, retain) NSString *path;

+ (TQNodeImport *)nodeWithPath:(NSString *)aPath;
@end
