#import "TQNodeVariable.h"
#import "../TQProgram.h"
#import "../TQDebug.h"
#import <llvm/IRBuilder.h>

using namespace llvm;

@interface TQNodeVariable (Private)
- (TQNodeVariable *)_getExistingIdenticalInBlock:(TQNodeBlock *)aBlock;
- (const char *)_llvmRegisterName:(NSString *)subname;
@end

@implementation TQNodeVariable
@synthesize name=_name, alloca=_alloca, forwarding=_forwarding;

+ (TQNodeVariable *)nodeWithName:(NSString *)aName
{
    return [[[self alloc] initWithName:aName] autorelease];
}

- (id)initWithName:(NSString *)aName
{
    if(!(self = [super init]))
        return nil;

    _name = [aName retain];

    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<var@ %@>", _name ? _name : @"unnamed"];
}

- (NSUInteger)hash
{
    return [_name hash];
}

- (BOOL)isEqual:(id)aObj
{
    if([aObj isKindOfClass:[TQNodeVariable class]] && [[(TQNodeVariable *)aObj name] isEqualToString:_name])
        return YES;
    else
        return NO;
}
- (TQNode *)referencesNode:(TQNode *)aNode
{
    return [aNode isEqual:self] ? self : nil;
}


- (void)dealloc
{
    [_name release];
    [super dealloc];
}

- (llvm::Value *)_getForwardingInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock
{
    TQNodeVariable *existingVar = [self _getExistingIdenticalInBlock:aBlock];
    if(existingVar)
        return [existingVar _getForwardingInProgram:aProgram block:aBlock];

    IRBuilder<> *builder = aBlock.builder;
    Value *forwarding;
    forwarding = builder->CreateLoad(builder->CreateStructGEP(_alloca, 1), [self _llvmRegisterName:@"forwardingPtr"]);
    forwarding = builder->CreateBitCast(forwarding, PointerType::getUnqual([self captureStructTypeInProgram:aProgram]), [self _llvmRegisterName:@"forwarding"]);

    return builder->CreateLoad(builder->CreateStructGEP(forwarding, 4));
}

- (llvm::Type *)captureStructTypeInProgram:(TQProgram *)aProgram
{
    static Type *captureType = NULL;
    if(captureType)
        return captureType;

    Type *i8PtrTy = aProgram.llInt8PtrTy;
    Type *intTy   = aProgram.llIntTy;

    captureType = StructType::create("struct._block_byref",
                                     i8PtrTy, // isa
                                     i8PtrTy, // forwarding
                                     intTy,   // flags (refcount)
                                     intTy,   // size ( = sizeof(id))
                                     i8PtrTy, // Captured variable (id)
                                     NULL);
    return captureType;
}

- (const char *)_llvmRegisterName:(NSString *)subname
{
    return _name ? [[NSString stringWithFormat:@"%@.%@", _name, subname] UTF8String] : "";
}

- (llvm::Value *)createStorageInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                 error:(NSError **)aoError
{
    if(_alloca)
        return _alloca;

    TQNodeVariable *existingVar = [self _getExistingIdenticalInBlock:aBlock];
    if(existingVar) {
        if(![existingVar generateCodeInProgram:aProgram block:aBlock error:aoError])
            return NULL;
        _alloca = existingVar.alloca;

        return _alloca;
    }
    Type *intTy   = aProgram.llIntTy;
    Type *i8PtrTy = aProgram.llInt8PtrTy;

    Type *byRefType = [self captureStructTypeInProgram:aProgram];
    IRBuilder<> entryBuilder(&aBlock.function->getEntryBlock(), aBlock.function->getEntryBlock().begin());
    AllocaInst *alloca = entryBuilder.CreateAlloca(byRefType, 0, [self _llvmRegisterName:@"alloca"]);

    // Initialize the variable to nil
    entryBuilder.CreateStore(entryBuilder.CreateBitCast(alloca, i8PtrTy),
                             entryBuilder.CreateStructGEP(alloca, 1, [self _llvmRegisterName:@"forwardingAssign"]));
    entryBuilder.CreateStore(ConstantInt::get(intTy, 0), entryBuilder.CreateStructGEP(alloca, 2, [self _llvmRegisterName:@"flags"]));
    Constant *size = ConstantExpr::getTruncOrBitCast(ConstantExpr::getSizeOf(byRefType), intTy);
    entryBuilder.CreateStore(size, entryBuilder.CreateStructGEP(alloca, 3, [self _llvmRegisterName:@"size"]));
    entryBuilder.CreateStore(ConstantPointerNull::get(aProgram.llInt8PtrTy),
                             entryBuilder.CreateStructGEP(alloca, 4, [self _llvmRegisterName:@"marked_variable"]));

    _alloca = alloca;

    return _alloca;
}
- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                 error:(NSError **)aoError
{
    if(_alloca)
        return [self _getForwardingInProgram:aProgram block:aBlock];

    if(![self createStorageInProgram:aProgram block:aBlock error:aoError])
        return NULL;

    return [self _getForwardingInProgram:aProgram block:aBlock];
}

- (llvm::Value *)store:(llvm::Value *)aValue
             inProgram:(TQProgram *)aProgram
                 block:(TQNodeBlock *)aBlock
                 error:(NSError **)aoError
{
    if(!_alloca) {
        if(![self createStorageInProgram:aProgram block:aBlock error:aoError])
            return NULL;
    }
    IRBuilder<> *builder = aBlock.builder;

    Value *forwarding = builder->CreateLoad(builder->CreateStructGEP(_alloca, 1), [self _llvmRegisterName:@"forwarding"]);
    forwarding = builder->CreateBitCast(forwarding, PointerType::getUnqual([self captureStructTypeInProgram:aProgram]));

    return aBlock.builder->CreateStore(aValue, builder->CreateStructGEP(forwarding, 4));
}

- (TQNodeVariable *)_getExistingIdenticalInBlock:(TQNodeBlock *)aBlock
{
    if(!_name)
        return nil;

    TQNodeVariable *existingVar = nil;
    if((existingVar = [aBlock.locals objectForKey:_name]) && existingVar != self)
        return existingVar;
    [aBlock.locals setObject:self forKey:_name];
    return nil;
}

@end


@implementation TQNodeSelf
- (id)init
{
    if(!(self = [super init]))
        return nil;
    self.name = @"self";
    return self;
}
@end

@implementation TQNodeSuper
- (id)init
{
    if(!(self = [super init]))
        return nil;
    self.name = @"super";
    return self;
}

- (llvm::Type *)_superStructTypeInProgram:(TQProgram *)aProgram
{
    if(_structType)
        return _structType;

    Type *i8PtrTy = aProgram.llInt8PtrTy;

    std::vector<Type*> fields;
    fields.push_back(i8PtrTy); // receiver
    fields.push_back(i8PtrTy); // (super)class
    _structType = StructType::get(aProgram.llModule->getContext(), fields, true);

    return _structType;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                 error:(NSError **)aoError
{
    IRBuilder<> *builder = aBlock.builder;
    IRBuilder<> entryBuilder(&aBlock.function->getEntryBlock(), aBlock.function->getEntryBlock().begin());
    AllocaInst *alloca = entryBuilder.CreateAlloca([self _superStructTypeInProgram:aProgram], 0, "super");

    TQNodeSelf *selfNode = [aBlock.locals objectForKey:@"self"];
    TQAssertSoft(selfNode, kTQSyntaxErrorDomain, kTQUnexpectedExpression, NULL, @"super is only applicable with in methods");
    Value *selfValue = [selfNode generateCodeInProgram:aProgram block:aBlock error:aoError];
    if(*aoError)
        return NULL;

    Value *superClass = builder->CreateCall(aProgram.TQObjectGetSuperClass, selfValue);

    builder->CreateStore(selfValue,  builder->CreateStructGEP(alloca, 0, "super.receiver"));
    builder->CreateStore(superClass, builder->CreateStructGEP(alloca, 1,  "super.class"));

    return builder->CreateBitCast(alloca, aProgram.llInt8PtrTy);
}

- (TQNode *)referencesNode:(TQNode *)aNode
{
    if([aNode isEqual:self])
        return self;
    else if([aNode isKindOfClass:[TQNodeSelf class]])
        return aNode;
    return nil;
}

@end
