#import "TQNodeOperator.h"
#import "TQNodeVariable.h"
#import "TQNodeMemberAccess.h"
#import "../TQProgram.h"
#import "../TQDebug.h"
#import "TQNodeNumber.h"

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

- (TQNode *)referencesNode:(TQNode *)aNode
{
    TQNode *ref = nil;
    if((ref = [_left referencesNode:aNode]))
        return ref;
    else if((ref = [_right referencesNode:aNode]))
        return ref;
    return nil;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoError
{
    IRBuilder<> *builder = aBlock.builder;
    if(_type == kTQOperatorAssign) {
        BOOL isVar = [_left isMemberOfClass:[TQNodeVariable class]];
        BOOL isProperty = [_left isMemberOfClass:[TQNodeMemberAccess class]];
        BOOL isGetterOp = [_left isMemberOfClass:[self class]] && [(TQNodeOperator*)_left type] == kTQOperatorGetter;
        TQAssertSoft(isVar || isProperty || isGetterOp, kTQSyntaxErrorDomain, kTQInvalidAssignee, NO, @"Only variables and object properties can be assigned to");

        // We must make sure the storage exists before evaluating the right side, so that if the assigned value is a
        // block, it can reference itself
        if(isVar)
            [(TQNodeVariable *)_left createStorageInProgram:aProgram block:aBlock error:aoError];
        Value *right = [_right generateCodeInProgram:aProgram block:aBlock error:aoError];
        [(TQNodeVariable *)_left store:right inProgram:aProgram block:aBlock error:aoError];
        if(*aoError)
            return NULL;
        return right;
    } else if(_type == kTQOperatorUnaryMinus) {
        Value *right = [_right generateCodeInProgram:aProgram block:aBlock error:aoError];
        Value *selector  = aProgram.llModule->getOrInsertGlobal("TQUnaryMinusOpSel", aProgram.llInt8PtrTy);
        return builder->CreateCall2(aProgram.objc_msgSend, right, builder->CreateLoad(selector));
    } else if(_type == kTQOperatorIncrement || _type == kTQOperatorDecrement) {
        assert(!_left || !_right);
        NSString *selName = _type == kTQOperatorIncrement ? @"TQAddOpSel" : @"TQSubOpSel";
        Value *selector  = aProgram.llModule->getOrInsertGlobal([selName UTF8String], aProgram.llInt8PtrTy);
        TQNode *incrementee = _left ? _left : _right;

        Value *one = [[TQNodeNumber nodeWithDouble:1.0] generateCodeInProgram:aProgram block:aBlock error:aoError];
        Value *beforeVal = [incrementee generateCodeInProgram:aProgram block:aBlock error:aoError];
        if(*aoError)
            return NULL;
        Value *incrementedVal = builder->CreateCall3(aProgram.objc_msgSend, beforeVal, builder->CreateLoad(selector), one);
        [incrementee store:incrementedVal inProgram:aProgram block:aBlock error:aoError];
        if(*aoError)
            return NULL;

        // Return original value and increment (var++)
        if(_left)
            return beforeVal;
        // Increment and return incremented value (++var)
        else
            return incrementedVal;
    } else if(_type == kTQOperatorEqual) {
        Value *left  = [_left generateCodeInProgram:aProgram block:aBlock error:aoError];
        Value *right = [_right generateCodeInProgram:aProgram block:aBlock error:aoError];
        return builder->CreateCall2(aProgram.TQObjectsAreEqual, left, right);
    } else if(_type == kTQOperatorInequal) {
        Value *left  = [_left generateCodeInProgram:aProgram block:aBlock error:aoError];
        Value *right = [_right generateCodeInProgram:aProgram block:aBlock error:aoError];
        return builder->CreateCall2(aProgram.TQObjectsAreNotEqual, left, right);
    } else {
        Value *left  = [_left generateCodeInProgram:aProgram block:aBlock error:aoError];
        Value *right = [_right generateCodeInProgram:aProgram block:aBlock error:aoError];

        Value *selector = NULL;
        switch(_type) {
            case kTQOperatorLesser:
                selector  = aProgram.llModule->getOrInsertGlobal("TQLTOpSel", aProgram.llInt8PtrTy);
                break;
            case kTQOperatorGreater:
                selector  = aProgram.llModule->getOrInsertGlobal("TQGTOpSel", aProgram.llInt8PtrTy);
                break;
            case kTQOperatorMultiply:
                selector  = aProgram.llModule->getOrInsertGlobal("TQMultOpSel", aProgram.llInt8PtrTy);
                break;
            case kTQOperatorDivide:
                selector  = aProgram.llModule->getOrInsertGlobal("TQDivOpSel", aProgram.llInt8PtrTy);
                break;
            case kTQOperatorAdd:
                selector  = aProgram.llModule->getOrInsertGlobal("TQAddOpSel", aProgram.llInt8PtrTy);
                break;
            case kTQOperatorSubtract:
                selector  = aProgram.llModule->getOrInsertGlobal("TQSubOpSel", aProgram.llInt8PtrTy);
                break;
            case kTQOperatorGreaterOrEqual:
                selector  = aProgram.llModule->getOrInsertGlobal("TQGTEOpSel", aProgram.llInt8PtrTy);
                break;
            case kTQOperatorLesserOrEqual:
                selector  = aProgram.llModule->getOrInsertGlobal("TQLTEOpSel", aProgram.llInt8PtrTy);
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
                break;

            default:
                TQAssertSoft(NO, kTQGenericErrorDomain, kTQGenericError, NULL, @"Unknown binary operator");
        }
        return builder->CreateCall3(aProgram.objc_msgSend, left, builder->CreateLoad(selector), right);
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
                 error:(NSError **)aoError
{
    assert(_type == kTQOperatorGetter);
    IRBuilder<> *builder = aBlock.builder;

    // Call []:=:
    Value *selector  = aProgram.llModule->getOrInsertGlobal("TQSetterOpSel", aProgram.llInt8PtrTy);
    Value *key = [_right generateCodeInProgram:aProgram block:aBlock error:aoError];
    Value *settee = [_left generateCodeInProgram:aProgram block:aBlock error:aoError];
    if(*aoError)
        return NULL;
    return builder->CreateCall4(aProgram.objc_msgSend, settee, builder->CreateLoad(selector), key, aValue);
}
@end

@implementation TQNodeMultiAssignOperator

- (id)init
{
    if(!(self = [super init]))
        return nil;

    _left  = [NSMutableArray array];
    _right = [NSMutableArray array];

    return self;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock error:(NSError **)aoError
{
    // We must first evaluate the values in order for cases like a,b = b,a to work
    std::vector<Value*> values;
    for(int i = 0; i < MIN([self.right count], [self.left count]); ++i) {
        values.push_back([[self.right objectAtIndex:i] generateCodeInProgram:aProgram block:aBlock error:aoError]);
    }

    // Then store the values
    unsigned maxIdx = [self.right count] - 1;
    for(int i = 0; i < [self.left count]; ++i) {
        [[self.left objectAtIndex:i] store:values[MIN(i, maxIdx)]
                                 inProgram:aProgram
                                     block:aBlock
                                     error:aoError];
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
@end
