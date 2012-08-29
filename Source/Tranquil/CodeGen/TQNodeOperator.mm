#import "TQNodeOperator.h"
#import "TQNode+Private.h"
#import "TQNodeVariable.h"
#import "TQNodeCustom.h"
#import "TQNodeConditionalBlock.h"
#import "TQNodeMemberAccess.h"
#import "TQProgram.h"
#import "../Shared/TQDebug.h"
#import "TQNodeNumber.h"
#import "TQNodeConditionalBlock.h"
#import "../Runtime/TQRuntime.h"
#import "TQNodeValid.h"
#import "../Runtime/TQNumber.h"
#import <llvm/Intrinsics.h>

using namespace llvm;

@implementation TQNodeOperator
@synthesize type=_type, left=_left, right=_right;

+ (TQNodeOperator *)nodeWithType:(TQOperatorType)aType left:(TQNode *)aLeft right:(TQNode *)aRight
{
    return [[[self alloc] initWithType:aType left:aLeft right:aRight] autorelease];
}

- (id)initWithType:(TQOperatorType)aType left:(TQNode *)aLeft right:(TQNode *)aRight
{
    if(!(self = [super init]))
        return nil;

    _type = aType;
    _left = [aLeft retain];
    _right = [aRight retain];

    return self;
}

- (void)dealloc
{
    [_left release];
    [_right release];
    [super dealloc];
}

- (BOOL)isEqual:(id)aOther
{
    if(![aOther isMemberOfClass:[self class]])
        return NO;
    return [_left isEqual:[aOther left]] && [_right isEqual:[aOther right]];
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    TQNode *ref = nil;
    if([self isEqual:aNode])
        return self;
    else if((ref = [_left referencesNode:aNode]))
        return ref;
    else if((ref = [_right referencesNode:aNode]))
        return ref;
    return nil;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    if(_left)
        aBlock(_left);
    if(_right)
        aBlock(_right);
}

- (BOOL)replaceChildNodesIdenticalTo:(TQNode *)aNodeToReplace with:(TQNode *)aNodeToInsert
{
    BOOL ret = NO;
    if(_left == aNodeToReplace) {
        self.left = aNodeToInsert;
        ret = YES;
    }
    if(_right == aNodeToReplace) {
        self.right = aNodeToInsert;
        ret = YES;
    }
    return ret;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    if(_type == kTQOperatorAssign) {
        BOOL isVar = [_left isKindOfClass:[TQNodeVariable class]];
        BOOL isProperty = [_left isMemberOfClass:[TQNodeMemberAccess class]];
        BOOL isGetterOp = [_left isMemberOfClass:[self class]] && [(TQNodeOperator*)_left type] == kTQOperatorGetter;
        TQAssertSoft(isVar || isProperty || isGetterOp, kTQSyntaxErrorDomain, kTQInvalidAssignee, NO, @"Only variables and object properties can be assigned to");

        // We must make sure the storage exists before evaluating the right side, so that if the assigned value is a
        // block, it can reference itself
        if(isVar)
            [(TQNodeVariable *)_left createStorageInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        Value *right = [_right generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        [(TQNodeVariable *)_left store:right inProgram:aProgram block:aBlock root:aRoot error:aoErr];
        if(*aoErr)
            return NULL;
        return right;
    } else if(_type == kTQOperatorUnaryMinus) {
        Value *right = [_right generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        Value *selector  = aProgram.llModule->getOrInsertGlobal("TQUnaryMinusOpSel", aProgram.llInt8PtrTy);
        Value *ret = aBlock.builder->CreateCall2(aProgram.objc_msgSend, right, aBlock.builder->CreateLoad(selector));
        [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];
        return ret;
    } else if(_type == kTQOperatorIncrement || _type == kTQOperatorDecrement) {
        TQAssert(!_left || !_right, @"Panic! in/decrement can't have both left&right hand sides");
        Value *beforeVal = NULL;

        // Return original value and increment (var++)
        TQNode *incrementee = _right;
        if(_left) {
            incrementee = _left;
            beforeVal = [incrementee generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        }
        TQNodeOperator *op = [TQNodeOperator nodeWithType:kTQOperatorIncrement ? kTQOperatorAdd : kTQOperatorSubtract
                                                     left:incrementee
                                                    right:[TQNodeNumber nodeWithDouble:1.0]];

        Value *incrementedVal = [op generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        [incrementee store:incrementedVal inProgram:aProgram block:aBlock root:aRoot error:aoErr];
        if(*aoErr)
            return NULL;

        if(beforeVal)
            return beforeVal;
        return incrementedVal;
    } else if(_type == kTQOperatorEqual) {
        Value *left  = [_left generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        Value *right = [_right generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        Value *ret = aBlock.builder->CreateCall2(aProgram.TQObjectsAreEqual, left, right);
        [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];
        return ret;
    } else if(_type == kTQOperatorInequal) {
        Value *left  = [_left generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        Value *right = [_right generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        Value *ret   = aBlock.builder->CreateCall2(aProgram.TQObjectsAreNotEqual, left, right);
        [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];
        return ret;
    } else if(_type == kTQOperatorAnd || _type == kTQOperatorOr) {
        // Compile `left ? left : right` or `left ? right : left`
        // We need to ensure the left side is only executed once
        Value *leftVal = [_left generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        TQNodeCustom *leftWrapper = [TQNodeCustom nodeReturningValue:leftVal];
        TQNodeTernaryOperator *tern = [TQNodeTernaryOperator nodeWithIfExpr:(_type == kTQOperatorAnd) ? _right : leftWrapper
                                                                       else:(_type == kTQOperatorAnd) ? leftWrapper  : _right];
        tern.condition = leftWrapper;
        tern.lineNumber = self.lineNumber;
        return [tern generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    } else {
        Value *left  = [_left generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
        Value *right = [_right generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];

        Value *selector = NULL;       // Selector to be sent in the general case (where one or both of the operands are not tagged numbers)
        TQNodeCustom *fastpath = nil; // Block to use in the case where both are tagged numbers
        Value *numTag     = ConstantInt::get(aProgram.llIntPtrTy, kTQNumberTag);
        Value *numValMask = ConstantInt::get(aProgram.llIntPtrTy, ~0xf);
        Value *nullPtr    = ConstantPointerNull::get(aProgram.llInt8PtrTy);
#define PtrToInt(val) aBlock.builder->CreatePtrToInt((val), aProgram.llIntPtrTy)
#define IntToPtr(val) aBlock.builder->CreateIntToPtr((val), aProgram.llInt8PtrTy)
#define IntCast(val) aBlock.builder->CreateBitCast((val), aProgram.llIntPtrTy)
#define FPCast(val) aBlock.builder->CreateBitCast((val), aProgram.llFPTy)
#define GET_AB() Value *a = FPCast(aBlock.builder->CreateAnd(PtrToInt(left),  numValMask)); \
                 Value *b = FPCast(aBlock.builder->CreateAnd(PtrToInt(right), numValMask))
#define GET_VALID() [[TQNodeValid node] generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr]
#define GET_TQNUM(val) IntToPtr(aBlock.builder->CreateOr(aBlock.builder->CreateAnd(IntCast(val), numValMask), numTag))

        switch(_type) {
            case kTQOperatorLesser:
                selector  = aProgram.llModule->getOrInsertGlobal("TQLTOpSel", aProgram.llInt8PtrTy);
                fastpath = [TQNodeCustom nodeWithBlock:^(TQProgram *p, TQNodeBlock *aBlock, TQNodeRootBlock *r) {
                    GET_AB();
                    return aBlock.builder->CreateSelect(aBlock.builder->CreateFCmpOLT(a, b), GET_VALID(), nullPtr);
                }];
                break;
            case kTQOperatorGreater:
                selector  = aProgram.llModule->getOrInsertGlobal("TQGTOpSel", aProgram.llInt8PtrTy);
                fastpath = [TQNodeCustom nodeWithBlock:^(TQProgram *p, TQNodeBlock *aBlock, TQNodeRootBlock *r) {
                    GET_AB();
                    return aBlock.builder->CreateSelect(aBlock.builder->CreateFCmpOGT(a, b), GET_VALID(), nullPtr);
                }];
                break;
            case kTQOperatorMultiply:
                selector  = aProgram.llModule->getOrInsertGlobal("TQMultOpSel", aProgram.llInt8PtrTy);
                fastpath = [TQNodeCustom nodeWithBlock:^(TQProgram *p, TQNodeBlock *aBlock, TQNodeRootBlock *r) {
                    GET_AB();
                    return GET_TQNUM(aBlock.builder->CreateFMul(a, b));
                }];
                break;
            case kTQOperatorDivide:
                selector  = aProgram.llModule->getOrInsertGlobal("TQDivOpSel", aProgram.llInt8PtrTy);
                fastpath = [TQNodeCustom nodeWithBlock:^(TQProgram *p, TQNodeBlock *aBlock, TQNodeRootBlock *r) {
                    GET_AB();
                    return GET_TQNUM(aBlock.builder->CreateFDiv(a, b));
                }];
                break;
            case kTQOperatorModulo:
                selector  = aProgram.llModule->getOrInsertGlobal("TQModOpSel", aProgram.llInt8PtrTy);
                break;
            case kTQOperatorAdd:
                selector  = aProgram.llModule->getOrInsertGlobal("TQAddOpSel", aProgram.llInt8PtrTy);
                fastpath = [TQNodeCustom nodeWithBlock:^(TQProgram *p, TQNodeBlock *aBlock, TQNodeRootBlock *r) {
                    GET_AB();
                    return GET_TQNUM(aBlock.builder->CreateFAdd(a, b));
                }];
                break;
            case kTQOperatorSubtract:
                selector  = aProgram.llModule->getOrInsertGlobal("TQSubOpSel", aProgram.llInt8PtrTy);
                fastpath = [TQNodeCustom nodeWithBlock:^(TQProgram *p, TQNodeBlock *aBlock, TQNodeRootBlock *r) {
                    GET_AB();
                    return GET_TQNUM(aBlock.builder->CreateFSub(a, b));
                }];
                break;
            case kTQOperatorGreaterOrEqual:
                selector  = aProgram.llModule->getOrInsertGlobal("TQGTEOpSel", aProgram.llInt8PtrTy);
                fastpath = [TQNodeCustom nodeWithBlock:^(TQProgram *p, TQNodeBlock *aBlock, TQNodeRootBlock *r) {
                    GET_AB();
                    return aBlock.builder->CreateSelect(aBlock.builder->CreateFCmpOGE(a, b), GET_VALID(), nullPtr);
                }];
                break;
            case kTQOperatorLesserOrEqual:
                selector  = aProgram.llModule->getOrInsertGlobal("TQLTEOpSel", aProgram.llInt8PtrTy);
                fastpath = [TQNodeCustom nodeWithBlock:^(TQProgram *p, TQNodeBlock *aBlock, TQNodeRootBlock *r) {
                    GET_AB();
                    return aBlock.builder->CreateSelect(aBlock.builder->CreateFCmpOLE(a, b), GET_VALID(), nullPtr);
                }];
                break;
            case kTQOperatorGetter:
                selector  = aProgram.llModule->getOrInsertGlobal("TQGetterOpSel", aProgram.llInt8PtrTy);
                break;
            case kTQOperatorLShift:
                selector  = aProgram.llModule->getOrInsertGlobal("TQLShiftOpSel", aProgram.llInt8PtrTy);
                break;
            case kTQOperatorRShift:
                selector  = aProgram.llModule->getOrInsertGlobal("TQRShiftOpSel", aProgram.llInt8PtrTy);
                break;
            case kTQOperatorConcat:
                selector  = aProgram.llModule->getOrInsertGlobal("TQConcatOpSel", aProgram.llInt8PtrTy);
                break;
            case kTQOperatorExponent:
                selector  = aProgram.llModule->getOrInsertGlobal("TQExpOpSel", aProgram.llInt8PtrTy);
                fastpath = [TQNodeCustom nodeWithBlock:^(TQProgram *p, TQNodeBlock *aBlock, TQNodeRootBlock *r) {
                    GET_AB();
                    Function *pow = Intrinsic::getDeclaration(p.llModule, Intrinsic::pow, p.llFPTy);
                    return GET_TQNUM(aBlock.builder->CreateCall2(pow, a, b));
                }];
                break;
            default:
                TQAssertSoft(NO, kTQGenericErrorDomain, kTQGenericError, NULL, @"Unknown binary operator");
        }
        TQNodeCustom *slowpath = [TQNodeCustom nodeWithBlock:^(TQProgram *p, TQNodeBlock *aBlock, TQNodeRootBlock *r) {
            return (Value *)aBlock.builder->CreateCall3(p.objc_msgSend, left, aBlock.builder->CreateLoad(selector), right);
        }];
        if(fastpath) {
            // If the operator supports a fast path then we must create the necessary branches
            Value *cond = aBlock.builder->CreateICmpNE(aBlock.builder->CreateAnd(aBlock.builder->CreateAnd(PtrToInt(left), PtrToInt(right)), numTag), ConstantInt::get(aProgram.llIntPtrTy, 0));

            BasicBlock *fastBB = BasicBlock::Create(aProgram.llModule->getContext(), "opFastpath", aBlock.function);
            BasicBlock *slowBB = BasicBlock::Create(aProgram.llModule->getContext(), "opSlowpath", aBlock.function);
            BasicBlock *contBB = BasicBlock::Create(aProgram.llModule->getContext(), "cont", aBlock.function);

            aBlock.builder->CreateCondBr(cond, fastBB, slowBB);

            IRBuilder<> fastBuilder(fastBB);
            aBlock.basicBlock = fastBB;
            aBlock.builder = &fastBuilder;
            Value *fastVal = [fastpath generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
            [self _attachDebugInformationToInstruction:fastVal inProgram:aProgram block:aBlock root:aRoot];

            IRBuilder<> slowBuilder(slowBB);
            aBlock.basicBlock = slowBB;
            aBlock.builder = &slowBuilder;
            Value *slowVal = [slowpath generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
            [self _attachDebugInformationToInstruction:fastVal inProgram:aProgram block:aBlock root:aRoot];

            IRBuilder<> *contBuilder = new IRBuilder<>(contBB);
            aBlock.basicBlock = contBB;
            aBlock.builder = contBuilder;

            fastBuilder.CreateBr(contBB);
            slowBuilder.CreateBr(contBB);

            PHINode *phi = contBuilder->CreatePHI(aProgram.llInt8PtrTy, 2);
            phi->addIncoming(fastVal, fastBB);
            phi->addIncoming(slowVal, slowBB);

            return phi;
        } else {
            Value *ret = [slowpath generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
            [self _attachDebugInformationToInstruction:ret inProgram:aProgram block:aBlock root:aRoot];
            return ret;
        }
    }
}

- (NSString *)description
{
    if(_type == kTQOperatorGetter)
        return [NSString stringWithFormat:@"<op@ %@[%@]>", _left, _right];
    else if(_type == kTQOperatorUnaryMinus)
        return [NSString stringWithFormat:@"<op@ -%@>", _right];
    else {
        NSString *opStr = nil;
        switch(_type) {
            case kTQOperatorMultiply: opStr = @"*";
            break;
            case kTQOperatorAdd: opStr = @"+";
            break;
            case kTQOperatorSubtract: opStr = @"-";
            break;
            case kTQOperatorDivide: opStr = @"/";
            break;
            case kTQOperatorAnd: opStr = @"&&";
            break;
            case kTQOperatorOr: opStr = @"||";
            break;
            case kTQOperatorLesser: opStr = @"<";
            break;
            case kTQOperatorAssign: opStr = @"=";
            break;
            case kTQOperatorGreater: opStr = @">";
            break;
            case kTQOperatorLesserOrEqual: opStr = @"<=";
            break;
            case kTQOperatorGreaterOrEqual: opStr = @"=>";
            break;
            case kTQOperatorEqual: opStr = @"==";
            break;
            case kTQOperatorInequal: opStr = @"!=";
            break;
            case kTQOperatorLShift: opStr = @"<<";
            break;
            case kTQOperatorRShift: opStr = @">>";
            break;
            case kTQOperatorConcat: opStr = @"..";
            break;
            case kTQOperatorExponent: opStr = @"^";
            break;

            default: opStr = @"<unknown>";
        }
        return [NSString stringWithFormat:@"<op@ %@ %@ %@>", _left, opStr, _right];
    }
}

- (llvm::Value *)store:(llvm::Value *)aValue
             inProgram:(TQProgram *)aProgram
                 block:(TQNodeBlock *)aBlock
                  root:(TQNodeRootBlock *)aRoot
                 error:(NSError **)aoErr
{
    assert(_type == kTQOperatorGetter);

    // Call []:=:
    Value *selector  = aProgram.llModule->getOrInsertGlobal("TQSetterOpSel", aProgram.llInt8PtrTy);
    Value *key = [_right generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    Value *settee = [_left generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    if(*aoErr)
        return NULL;

    IRBuilder<> *builder = aBlock.builder;
    return builder->CreateCall4(aProgram.objc_msgSend, settee, builder->CreateLoad(selector), key, aValue);
}
@end

@implementation TQNodeMultiAssignOperator
@synthesize left=_left, right=_right, type=_type;
- (id)init
{
    if(!(self = [super init]))
        return nil;

    _type = kTQOperatorAssign;
    _left  = [NSMutableArray array];
    _right = [NSMutableArray array];

    return self;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    // We must first evaluate the values in order for cases like a,b = b,a to work
    std::vector<Value*> values;
    for(int i = 0; i < MIN([self.right count], [self.left count]); ++i) {
        values.push_back([[self.right objectAtIndex:i] generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr]);
    }

    // Then store the values
    unsigned maxIdx = [self.right count] - 1;
    Value *val;
    for(int i = 0; i < [self.left count]; ++i) {
        val = values[MIN(i, maxIdx)];
        switch(_type) {
            case kTQOperatorAdd:
            case kTQOperatorSubtract:
            case kTQOperatorMultiply:
            case kTQOperatorDivide: {
                TQNodeOperator *op = [TQNodeOperator nodeWithType:_type left:[self.left objectAtIndex:i] right:[TQNodeCustom nodeReturningValue:val]];
                val = [op generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
            } break;
            case kTQOperatorAssign:
                // Do nothing
            break;
            default:
                TQAssert(NO, @"Unsupported operator type for multi assign");
        }
        [[self.left objectAtIndex:i] store:val
                                 inProgram:aProgram
                                     block:aBlock
                                      root:aRoot
                                     error:aoErr];
    }

    return NULL;
}

- (NSString *)description
{
    NSMutableString *str = [NSMutableString stringWithString:@"<multiassgn@"];
    for(TQNode *assignee in self.left) {
        [str appendFormat:@"%@, ", assignee];
    }
    [str appendString:@"= "];
    for(TQNode *value in self.right) {
        [str appendFormat:@"%@, ", value];
    }
    [str appendString:@">"];
    return str;
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    TQNode *ref = nil;
    if((ref = [self.left tq_referencesNode:aNode]))
        return ref;
    else if((ref = [self.right tq_referencesNode:aNode]))
        return ref;
    return nil;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    for(TQNode *node in self.left) {
        aBlock(node);
    }
    for(TQNode *node in self.right) {
        aBlock(node);
    }
}
@end
