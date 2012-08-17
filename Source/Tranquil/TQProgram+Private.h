@class TQNodeRootBlock, NSString, NSError;

@interface TQProgram (Private)
- (TQNodeRootBlock *)_rootFromFile:(NSString *)aPath error:(NSError **)aoErr;
- (TQNodeRootBlock *)_parseScript:(NSString *)aScript error:(NSError **)aoErr;
- (NSString *)_resolveImportPath:(NSString *)aPath;
@end
