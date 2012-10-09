#import "TQNode.h"
#import "../Shared/TQDebug.h"
#import "TQNodeBlock.h"

using namespace llvm;

@implementation TQNode
@synthesize lineNumber=_lineNumber;

+ (TQNode *)node
{
    return [[self new] autorelease];
}

- (id)init
{
    if(!(self = [super init]))
        return nil;
    _lineNumber = NSNotFound;
    return self;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    TQLog(@"Code generation has not been implemented for %@.", [self class]);
    return NULL;
}

- (llvm::Value *)store:(llvm::Value *)aValue
             inProgram:(TQProgram *)aProgram
                 block:(TQNodeBlock *)aBlock
                  root:(TQNodeRootBlock *)aRoot
                 error:(NSError **)aoErr
{
    TQLog(@"Store has not been implemented for %@.", [self class]);
    return NULL;
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    TQLog(@"Node reference check has not been implemented for %@.", [self class]);
    return nil;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    TQLog(@"Node iteration has not been implemented for %@.", [self class]);
}

- (BOOL)insertChildNode:(TQNode *)aNodeToInsert before:(TQNode *)aNodeToShift
{
    TQLog(@"%@ does not support child node insertion.", [self class]);
    return NO;
}

- (BOOL)insertChildNode:(TQNode *)aNodeToInsert after:(TQNode *)aNodeToShift
{
    TQLog(@"%@ does not support child node insertion.", [self class]);
    return NO;
}

- (BOOL)replaceChildNodesIdenticalTo:(TQNode *)aNodeToReplace with:(TQNode *)aNodeToInsert
{
    TQLog(@"%@ does not support child node replacement.", [self class]);
    return NO;
}

- (void)_attachDebugInformationToInstruction:(llvm::Value *)aInst inProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock root:(TQNodeRootBlock *)aRoot
{
    //NSLog(@"line: %ld %@", _lineNumber, self);
    if(_lineNumber == NSNotFound)
        return;

    //aBlock.builder->SetCurrentDebugLocation(DebugLoc::get(self.lineNumber, 0, (MDNode*)aBlock.debugInfo, NULL)); <- Crashes llc

    Value *args[] = {
        ConstantInt::get(aProgram.llIntTy, _lineNumber),
        ConstantInt::get(aProgram.llIntTy, 0),
        (Value *)aRoot.debugUnit,
        //(Value *)aBlock.debugInfo,
        DILocation(NULL)
    };
    LLVMContext *ctx = &aProgram.llModule->getContext();
    DILocation loc = DILocation(MDNode::get(*ctx, args));
    dyn_cast<Instruction>(aInst)->setMetadata(ctx->getMDKindID("dbg"), loc);
}

- (void)setLineNumber:(NSUInteger)aLineNo
{
    _lineNumber = aLineNo;
    [self iterateChildNodes:^(TQNode *aChild) {
        aChild.lineNumber = aLineNo;
    }];
}

- (NSString *)toString
{
    return [self description];
}
@end

@implementation NSArray (TQReferencesNode)
- (TQNode *)tq_referencesNode:(TQNode *)aNode
{
    TQNode *ref;
    for(TQNode *n in self) {
        ref = [n referencesNode:aNode];
        if(ref)
            return ref;
    }
    return nil;
}
@end
