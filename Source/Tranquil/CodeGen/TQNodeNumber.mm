#import "TQNodeNumber.h"
#import "../TQProgram.h"

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

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoError
{
    Module *mod = aProgram.llModule;

    // Returns [NSNumber numberWithDouble:_value]
    NSString *globalName = [NSString stringWithFormat:@"TQConstNum_%f", [_value doubleValue]];
    Value *num =  mod->getGlobalVariable([globalName UTF8String], true);
    if(!num) {
        Function *rootFunction = aProgram.rootBlock.function;
        IRBuilder<> rootBuilder(&rootFunction->getEntryBlock(), rootFunction->getEntryBlock().begin());

        Value *selector = rootBuilder.CreateLoad(mod->getOrInsertGlobal("TQNumberWithDoubleSel", aProgram.llInt8PtrTy));
        Value *klass    = mod->getOrInsertGlobal("OBJC_CLASS_$_TQNumber", aProgram.llInt8Ty);
        ConstantFP *doubleValue = ConstantFP::get(aProgram.llModule->getContext(), APFloat([_value doubleValue]));

        Value *result = rootBuilder.CreateCall3(aProgram.objc_msgSend, klass, selector, doubleValue);
        result = rootBuilder.CreateCall(aProgram.objc_retain, result);

        num = new GlobalVariable(*mod, aProgram.llInt8PtrTy, false, GlobalVariable::InternalLinkage,
                                 ConstantPointerNull::get(aProgram.llInt8PtrTy), [globalName UTF8String]);

        rootBuilder.CreateStore(result, num);
    }
    return aBlock.builder->CreateLoad(num);
   }
@end
