#import "TQNodeVariable.h"
#import "TQNode+Private.h"
#import "TQNodeBlock.h"
#import "TQProgram.h"
#import "../Shared/TQDebug.h"
#import <llvm/Support/IRBuilder.h>

using namespace llvm;

@interface TQNodeVariable (Private)
- (TQNodeVariable *)_getExistingIdenticalInBlock:(TQNodeBlock *)aBlock program:(TQProgram *)aProgram;
- (const char *)_llvmRegisterName:(NSString *)subname;
@end

@implementation TQNodeVariable
@synthesize name=_name, alloca=_alloca, forwarding=_forwarding, isGlobal=_isGlobal, isAnonymous=_isAnonymous, shadows=_shadows;

+ (TQNodeVariable *)node
{
    return (TQNodeVariable *)[super node];
}

+ (TQNodeVariable *)tempVar
{
    TQNodeVariable *ret = [self node];
    ret.isAnonymous = YES;
    return ret;
}

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
    return [NSString stringWithFormat:@"<var(%@)@ %@>", _isGlobal ? @"global" : @"local", _name ? _name : @"unnamed"];
}

- (NSString *)toString
{
    return _name;
}

- (NSUInteger)hash
{
    return [_name hash];
}

- (void)setIsAnonymous:(BOOL)flag
{
    _isAnonymous = flag;
    // An anonymous still needs an identifier so that it can be captured properly (only used at compilation time)
    if(_isAnonymous)
        self.name = [[NSProcessInfo processInfo] globallyUniqueString];
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
    return (aNode == self) || (_name && [aNode isEqual:self]) ? self : nil;
}

- (void)iterateChildNodes:(TQNodeIteratorBlock)aBlock
{
    // Nothing to iterate
}

- (void)dealloc
{
    [_name release];
    [super dealloc];
}

- (llvm::Value *)_getForwardingInProgram:(TQProgram *)aProgram block:(TQNodeBlock *)aBlock root:(TQNodeRootBlock *)aRoot
{
    TQNodeVariable *existingVar = [self _getExistingIdenticalInBlock:aBlock program:aProgram];
    if(existingVar)
        return [existingVar _getForwardingInProgram:aProgram block:aBlock root:aRoot];
    if(_isAnonymous)
        return _alloca;

    IRBuilder<> *builder = aBlock.builder;
    Value *forwarding;
    forwarding = builder->CreateLoad(builder->CreateStructGEP(_alloca, 1), [self _llvmRegisterName:@"forwardingPtr"]);
    forwarding = builder->CreateBitCast(forwarding, PointerType::getUnqual([[self class] captureStructTypeInProgram:aProgram]), [self _llvmRegisterName:@"forwarding"]);

    Value *ret = builder->CreateLoad(builder->CreateStructGEP(forwarding, 4));
    [self _attachDebugInformationToInstruction:(Instruction *)ret inProgram:aProgram block:aBlock root:aRoot];
    return ret;
}

+ (llvm::Type *)captureStructTypeInProgram:(TQProgram *)aProgram
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
    return (_name && !_isAnonymous) ? [[NSString stringWithFormat:@"%@.%@", _name, subname] UTF8String] : "";
}

- (llvm::Value *)createStorageInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    TQNodeVariable *existingVar = [self _getExistingIdenticalInBlock:aBlock program:aProgram];
    if(existingVar) {
        if(![existingVar createStorageInProgram:aProgram block:aBlock root:aRoot error:aoErr])
            return NULL;
        _alloca      = existingVar.alloca;
        _isGlobal    = existingVar.isGlobal;
        _isAnonymous = existingVar.isAnonymous;

        return _alloca;
    }

    if(_alloca)
        return _alloca;

    Type *intTy   = aProgram.llIntTy;
    Type *i8PtrTy = aProgram.llInt8PtrTy;

    Type *byRefType = [[self class] captureStructTypeInProgram:aProgram];
    IRBuilder<> entryBuilder(&aBlock.function->getEntryBlock(), aBlock.function->getEntryBlock().begin());

    if(aBlock == aRoot) {
        _isGlobal = YES;
        [[aProgram globals] setObject:self forKey:_name];
        const char *globalName = [[NSString stringWithFormat:@"TQGlobalVar_%@", _name] UTF8String];
        _alloca = aProgram.llModule->getGlobalVariable(globalName, true);
        if(!_alloca)
            _alloca = new GlobalVariable(*aProgram.llModule, byRefType, false, GlobalVariable::InternalLinkage, ConstantAggregateZero::get(byRefType), globalName);
    } else
        _alloca = entryBuilder.CreateAlloca(byRefType, 0, [self _llvmRegisterName:@"alloca"]);

    // Initialize the variable to nil
    entryBuilder.CreateStore(entryBuilder.CreateBitCast(_alloca, i8PtrTy),
                             entryBuilder.CreateStructGEP(_alloca, 1, [self _llvmRegisterName:@"forwardingAssign"]));
    entryBuilder.CreateStore(ConstantInt::get(intTy, 0), entryBuilder.CreateStructGEP(_alloca, 2, [self _llvmRegisterName:@"flags"]));
    Constant *size = ConstantExpr::getTruncOrBitCast(ConstantExpr::getSizeOf(byRefType), intTy);
    entryBuilder.CreateStore(size, entryBuilder.CreateStructGEP(_alloca, 3, [self _llvmRegisterName:@"size"]));

    if(!_isGlobal) // Globals are pre initialized
        entryBuilder.CreateStore(ConstantPointerNull::get(aProgram.llInt8PtrTy),
                                 entryBuilder.CreateStructGEP(_alloca, 4, [self _llvmRegisterName:@"marked_variable"]));

    return _alloca;
}
- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    if(_alloca)
        return [self _getForwardingInProgram:aProgram block:aBlock root:aRoot];

    if(![self createStorageInProgram:aProgram block:aBlock root:aRoot error:aoErr])
        return NULL;

    return [self _getForwardingInProgram:aProgram block:aBlock root:aRoot];
}

- (llvm::Value *)store:(llvm::Value *)aValue
             inProgram:(TQProgram *)aProgram
                 block:(TQNodeBlock *)aBlock
                  root:(TQNodeRootBlock *)aRoot
                 error:(NSError **)aoErr
{
    return [self store:aValue retained:YES inProgram:aProgram block:aBlock root:aRoot error:aoErr];
}

- (llvm::Value *)store:(llvm::Value *)aValue
              retained:(BOOL)aRetain
             inProgram:(TQProgram *)aProgram
                 block:(TQNodeBlock *)aBlock
                  root:(TQNodeRootBlock *)aRoot
                 error:(NSError **)aoErr
{
    TQNodeVariable *existingVar = [self _getExistingIdenticalInBlock:aBlock program:aProgram];
    if(existingVar)
        return [existingVar store:aValue inProgram:aProgram block:aBlock root:aRoot error:aoErr];

    if(_isAnonymous) {
        _alloca = aValue;
        return NULL;
    }

    if(!_alloca && ![self createStorageInProgram:aProgram block:aBlock root:aRoot error:aoErr]) {
        return NULL;
    }

    Value *forwarding = aBlock.builder->CreateLoad(aBlock.builder->CreateStructGEP(_alloca, 1), [self _llvmRegisterName:@"forwarding"]);
    forwarding = aBlock.builder->CreateBitCast(forwarding, PointerType::getUnqual([[self class] captureStructTypeInProgram:aProgram]));

    if(!aRetain) {
        aBlock.builder->CreateStore(aValue, aBlock.builder->CreateStructGEP(forwarding, 4));
        return NULL;
    }
    Function *storeFun = aProgram.objc_storeStrong;
    // If the variable is a capture, or a global we need to use TQStoreStrong because if the assigned value is a
    // stack block it would escape and cause a crash
    if(_isGlobal || [aBlock.capturedVariables objectForKey:_name])
        storeFun = aProgram.TQStoreStrong;

    CallInst *storeCall = aBlock.builder->CreateCall2(storeFun, aBlock.builder->CreateStructGEP(forwarding, 4), aValue);
    storeCall->addAttribute(~0, Attribute::NoUnwind);

    return NULL;
}

- (void)generateRetainInProgram:(TQProgram *)aProgram
                          block:(TQNodeBlock *)aBlock
                           root:(TQNodeRootBlock *)aRoot
{
    if(_isAnonymous)
        return;
    TQNodeVariable *existingVar = [self _getExistingIdenticalInBlock:aBlock program:aProgram];
    if(existingVar)
        return [existingVar generateRetainInProgram:aProgram block:aBlock root:aRoot];

    CallInst *retainCall = aBlock.builder->CreateCall(aProgram.objc_retain, [self _getForwardingInProgram:aProgram block:aBlock root:aRoot]);
    retainCall->addAttribute(~0, Attribute::NoUnwind);
}

- (void)generateReleaseInProgram:(TQProgram *)aProgram
                           block:(TQNodeBlock *)aBlock
                           root:(TQNodeRootBlock *)aRoot
{
    if(_isGlobal || _isAnonymous) // Global values are only released when they are replaced
        return;                   // Anons are simply managed by their capturing blocks
    TQNodeVariable *existingVar = [self _getExistingIdenticalInBlock:aBlock program:aProgram];
    if(existingVar)
        return [existingVar generateReleaseInProgram:aProgram block:aBlock root:aRoot];

    CallInst *releaseCall = aBlock.builder->CreateCall(aProgram.objc_release, [self _getForwardingInProgram:aProgram block:aBlock root:aRoot]);
    releaseCall->addAttribute(~0, Attribute::NoUnwind);
    SmallVector<llvm::Value*,1> args;
    releaseCall->setMetadata("clang.imprecise_release", llvm::MDNode::get(aProgram.llModule->getContext(), args));
}

- (TQNodeVariable *)_getExistingIdenticalInBlock:(TQNodeBlock *)aBlock program:(TQProgram *)aProgram
{
    if(!_name)
        return nil;

    TQNodeVariable *existingVar = nil;

    if(!_isGlobal && (existingVar = [aBlock.locals objectForKey:_name]) && (existingVar != self || _shadows))
        return existingVar == self ? nil : existingVar;
    else if((existingVar = [[aProgram globals] objectForKey:_name]) && existingVar != self && !_shadows)
        return existingVar;

    [aBlock.locals setObject:self forKey:_name];
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    TQNodeVariable *copy = [[[self class] alloc] init];
    copy.isAnonymous = _isAnonymous;
    copy.name        = _name;
    copy->_isGlobal  = _isGlobal;
    copy.alloca      = _alloca;
    copy.shadows     = _shadows;

    return copy;
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
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    IRBuilder<> *builder = aBlock.builder;
    IRBuilder<> entryBuilder(&aBlock.function->getEntryBlock(), aBlock.function->getEntryBlock().begin());
    AllocaInst *alloca = entryBuilder.CreateAlloca([self _superStructTypeInProgram:aProgram], 0, "super");

    TQNodeSelf *selfNode = [aBlock.locals objectForKey:@"self"];
    TQAssertSoft(selfNode, kTQSyntaxErrorDomain, kTQUnexpectedExpression, NULL, @"super is only applicable with in methods");
    Value *selfValue = [selfNode generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    if(*aoErr)
        return NULL;

    Value *superClass = builder->CreateCall(aProgram.TQObjectGetSuperClass, selfValue);

    builder->CreateStore(selfValue,  builder->CreateStructGEP(alloca, 0, "super.receiver"));
    builder->CreateStore(superClass, builder->CreateStructGEP(alloca, 1,  "super.class"));

    return builder->CreateBitCast(alloca, aProgram.llInt8PtrTy);
}

- (llvm::Value *)store:(llvm::Value *)aValue
             inProgram:(TQProgram *)aProgram
                 block:(TQNodeBlock *)aBlock
                  root:(TQNode *)aRoot
                 error:(NSError **)aoErr
{
    TQAssertSoft(NO, kTQSyntaxErrorDomain, kTQInvalidAssignee, NO, @"Tried to assign to super! on line %ld", self.lineNumber);
    return NULL;
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
