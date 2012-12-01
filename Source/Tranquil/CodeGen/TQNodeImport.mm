#import "TQNodeImport.h"
#import "TQNode+Private.h"
#import "TQNodeBlock.h"
#import "ObjCSupport/TQHeaderParser.h"
#import "TQProgram.h"
#import <dlfcn.h>

using namespace llvm;

@implementation TQNodeImport
@synthesize path=_path;

+ (TQNodeImport *)nodeWithPath:(NSString *)aPath
{
    TQNodeImport *ret = (TQNodeImport *)[self node];
    ret->_path = [aPath retain];
    return ret;
}
- (void)dealloc
{
    [_path release];
    [super dealloc];
}

- (id)referencesNode:(TQNode *)aNode
{
    if([aNode isEqual:self])
        return self;
    return nil;
}


- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    // No subnodes
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<import: %@>", _path];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    NSString *path = [aProgram _resolveImportPath:_path];
    TQAssertSoft(path, kTQGenericErrorDomain, kTQGenericError, NULL, @"No file found for '%@'", _path);
    if([aProgram.evaluatedPaths containsObject:path])
        return ConstantPointerNull::get(aProgram.llInt8PtrTy);

    [aProgram.evaluatedPaths addObject:path];
    if([[path pathExtension] isEqualToString:@"h"]) {
        // If it's a framework and we are not in AOT mode, we should load it
        if(!aProgram.useAOTCompilation && [path rangeOfString:@".framework"].location != NSNotFound) {
            NSArray *components = [path pathComponents];
            NSString *frameworkPath;
            for(int i = [components count] - 1; i >= 0; --i) {
                if([[components objectAtIndex:i] hasSuffix:@".framework"]) {
                    frameworkPath = [[components subarrayWithRange:(NSRange) { 0, i+1 }] componentsJoinedByString:@"/"];
                    frameworkPath = [frameworkPath stringByAppendingFormat:@"/%@", [[components objectAtIndex:i] stringByDeletingPathExtension]];
                }
            }
            dlopen([frameworkPath fileSystemRepresentation], RTLD_GLOBAL);
        }
        [aProgram.objcParser parseHeader:path];
        return ConstantPointerNull::get(aProgram.llInt8PtrTy);
    } else {
        TQNodeRootBlock *importedRoot = [aProgram _rootFromFile:path error:aoErr];
        if(*aoErr)
            return NULL;
        Value *rootFun = [importedRoot generateCodeInProgram:aProgram block:aBlock root:importedRoot error:aoErr];
        if(*aoErr)
            return NULL;
        Value *ret = aBlock.builder->CreateCall(rootFun);
        [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];
        return ret;
    }
}
@end
