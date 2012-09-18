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
}
@end
