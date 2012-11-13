#import "TQNodeImport.h"
#import "TQNode+Private.h"
#import "TQNodeBlock.h"
#import "../Runtime/OFString+TQAdditions.h"
#import "ObjCSupport/TQHeaderParser.h"
#import "TQProgram.h"
#import <dlfcn.h>

using namespace llvm;

@implementation TQNodeImport
@synthesize path=_path;

+ (TQNodeImport *)nodeWithPath:(OFString *)aPath
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

- (OFString *)description
{
    return [OFString stringWithFormat:@"<import: %@>", _path];
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(TQError **)aoErr
{
    OFString *path = [aProgram _resolveImportPath:_path];
    if(!path || [aProgram.evaluatedPaths containsObject:path])
        return NULL;

    [aProgram.evaluatedPaths addObject:path];
    if([[path pathExtension] isEqual:@"h"]) {
        // If it's a framework and we are not in AOT mode, we should load it
        if(!aProgram.useAOTCompilation && [path rangeOfString:@".framework"].location != OF_NOT_FOUND) {
            OFArray *components = [path pathComponents];
            OFString *frameworkPath;
            for(int i = [components count] - 1; i >= 0; --i) {
                if([[components objectAtIndex:i] hasSuffix:@".framework"]) {
                    frameworkPath = [[components objectsInRange:(of_range_t) { 0, i+1 }] componentsJoinedByString:@"/"];
                    frameworkPath = [frameworkPath stringByAppendingFormat:@"/%@", [[components objectAtIndex:i] stringByDeletingPathExtension]];
                }
            }
            dlopen([frameworkPath UTF8String], RTLD_GLOBAL);
        }
        [aProgram.objcParser parseHeader:path];
        return NULL;
    } else {
        TQNodeRootBlock *importedRoot = [aProgram _rootFromFile:path error:aoErr];
        if(!importedRoot || *aoErr)
            return NULL;
        Value *rootFun = [importedRoot generateCodeInProgram:aProgram block:aBlock root:importedRoot error:aoErr];
        Value *ret = aBlock.builder->CreateCall(rootFun);
        [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];
        return ret;
    }
}
@end
