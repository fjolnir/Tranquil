#import "TQNodeNumber.h"
#import "TQNodeBlock.h"
#import "TQProgram.h"
#import "../Runtime/TQNumber.h"

using namespace llvm;

@implementation TQNodeNumber
@synthesize value=_value;

+ (TQNodeNumber *)nodeWithDouble:(double)aDouble
{
    return [[[self alloc] initWithDouble:aDouble] autorelease];
}

- (id)initWithDouble:(double)aDouble
{
    if(!(self = [super init]))
        return nil;

    _value = [[NSNumber alloc] initWithDouble:aDouble];

    return self;
}

- (void)dealloc
{
    [_value release];
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<num@ %f>", _value.doubleValue];
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    return [aNode isEqual:self] ? self : nil;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    // Nothing to iterate
}

#define B aBlock.builder
- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
#ifndef __LP64__
#error "numbers not implemented for 32bit"
#endif
    float value = [_value floatValue];
    Value *numTag = ConstantInt::get(aProgram.llIntPtrTy, kTQNumberTag);

    Value *val;
    if(value == INFINITY || value == -INFINITY)
        val = ConstantFP::getInfinity(aProgram.llFloatTy, value == -INFINITY);
    else
        val = ConstantFP::get(aProgram.llFloatTy, value);
    val = B->CreateZExt(B->CreateBitCast(val, aProgram.llIntTy), aProgram.llIntPtrTy);
    val = B->CreateOr(B->CreateShl(val, 4), numTag);

    return B->CreateIntToPtr(val, aProgram.llInt8PtrTy);
#if 0
    Module *mod = aProgram.llModule;

    // Returns [NSNumber numberWithDouble:_value]
    NSString *globalName = [NSString stringWithFormat:@"TQConstNum_%f", [_value doubleValue]];
    Value *num =  mod->getGlobalVariable([globalName UTF8String], true);
    if(!num) {
        Function *rootFunction = aRoot.function;
        IRBuilder<> rootBuilder(&rootFunction->getEntryBlock(), rootFunction->getEntryBlock().begin());

        Value *selector = rootBuilder.CreateLoad(mod->getOrInsertGlobal("TQNumberWithDoubleSel", aProgram.llInt8PtrTy));
        Value *klass    = mod->getOrInsertGlobal("OBJC_CLASS_$_TQNumber", aProgram.llInt8Ty);
        ConstantFP *doubleValue = ConstantFP::get(aProgram.llModule->getContext(), APFloat([_value doubleValue]));

        Value *result = rootBuilder.CreateCall3(aProgram.objc_msgSend, klass, selector, doubleValue, "");
        result = rootBuilder.CreateCall(aProgram.objc_retain, result);

        num = new GlobalVariable(*mod, aProgram.llInt8PtrTy, false, GlobalVariable::InternalLinkage,
                                 ConstantPointerNull::get(aProgram.llInt8PtrTy), [globalName UTF8String]);

        rootBuilder.CreateStore(result, num);
    }
    return aBlock.builder->CreateLoad(num);
#endif
   }
@end
