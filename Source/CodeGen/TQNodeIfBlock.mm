#import "TQNodeIfBlock.h"
#import "TQProgram.h"
#import "TQNodeVariable.h"


using namespace llvm;

@implementation TQNodeIfBlock
@synthesize condition=_condition;

+ (TQNodeIfBlock *)node { return (TQNodeIfBlock *)[super node]; }

- (id)init
{
    if(!(self = [super init]))
        return nil;

    // If blocks don't take arguments
    [[self arguments] removeAllObjects];

    return self;
}

- (NSString *)description
{
    NSMutableString *out = [NSMutableString stringWithString:@"<if@ "];
    [out appendFormat:@"(%@)", _condition];
    [out appendString:@" {\n"];

    if(self.statements.count > 0) {
        [out appendString:@"\n"];
        for(TQNode *stmt in self.statements) {
            [out appendFormat:@"\t%@\n", stmt];
        }
    }
    [out appendString:@"}>"];
    return out;
}

- (void)dealloc
{
    [_condition release];
    [super dealloc];
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    TQNode *ref = nil;

    if((ref = [_condition referencesNode:aNode]))
        return ref;
    if((ref = [self.statements tq_referencesNode:aNode]))
        return ref;
    return nil;
}


#pragma mark - Code generation

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoErr
{
    return NULL;
}


#pragma mark - Unused methods from TQNodeBlock
- (NSString *)signature
{
    return nil;
}
- (BOOL)addArgument:(NSString *)aArgument error:(NSError **)aoError
{
    return NO;
}
- (llvm::Constant *)_generateBlockDescriptorInProgram:(TQProgram *)aProgram
{
    return NULL;
}
- (llvm::Value *)_generateBlockLiteralInProgram:(TQProgram *)aProgram parentBlock:(TQNodeBlock *)aParentBlock
{
    return NULL;
}
- (llvm::Function *)_generateCopyHelperInProgram:(TQProgram *)aProgram
{
    return NULL;
}
- (llvm::Function *)_generateDisposeHelperInProgram:(TQProgram *)aProgram
{
    return NULL;
}
- (llvm::Function *)_generateInvokeInProgram:(TQProgram *)aProgram error:(NSError **)aoErr
{
    return NULL;
}
- (llvm::Type *)_blockDescriptorTypeInProgram:(TQProgram *)aProgram
{
    return NULL;
}
- (llvm::Type *)_genericBlockLiteralTypeInProgram:(TQProgram *)aProgram
{
    return NULL;
}
- (llvm::Type *)_blockLiteralTypeInProgram:(TQProgram *)aProgram
{
    return NULL;
}
- (llvm::Type *)_byRefTypeInProgram:(TQProgram *)aProgram
{
    return NULL;
}
@end


