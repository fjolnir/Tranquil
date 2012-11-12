#import "TQNodeMethod.h"
#import "TQNodeMessage.h"
#import "TQNodeArgument.h"
#import "TQNodeClass.h"
#import "TQProgram.h"
#import "../Shared/TQDebug.h"
#import "TQNodeArgumentDef.h"
#import "TQNodeOperator.h"
#import "TQNodeVariable.h"
#import "TQNodeNothing.h"
#import "ObjCSupport/TQHeaderParser.h"
#import <objc/runtime.h>

using namespace llvm;

@implementation TQNodeMethod
@synthesize type=_type;

+ (TQNodeMethod *)node { return [[self new] autorelease]; }

+ (TQNodeMethod *)nodeWithType:(TQMethodType)aType
{
    return [[[self alloc] initWithType:aType] autorelease];
}

- (id)initWithType:(TQMethodType)aType
{
    if(!(self = [super init]))
        return nil;

    _type = aType;

    [[self arguments] removeAllObjects];
    [self addArgument:[TQNodeMethodArgumentDef nodeWithName:@"__blk" selectorPart:nil] error:nil];
    TQNodeMethodArgumentDef *selfArg = [TQNodeMethodArgumentDef nodeWithName:@"self" selectorPart:nil];
    selfArg.unretained = YES;
    [self addArgument:selfArg error:nil];


    return self;
}

- (id)init
{
    return [self initWithType:kTQInstanceMethod];
}

- (BOOL)addArgument:(TQNodeMethodArgumentDef *)aArgument error:(TQError **)aoErr
{
    [self.arguments addObject:aArgument];
    return YES;
}

- (OFString *)description
{
    OFMutableString *out = [OFMutableString stringWithString:@"<meth@ "];
    switch(_type) {
        case kTQClassMethod:
            [out appendString:@"+ "];
            break;
        case kTQInstanceMethod:
        default:
            [out appendString:@"- "];
    }
    for(TQNodeMethodArgumentDef *arg in self.arguments) {
        [out appendFormat:@"%@ ", arg];
    }
    [out appendString:@"{"];
    if(self.statements.count > 0) {
        [out appendString:@"\n"];
        for(TQNode *stmt in self.statements) {
            [out appendFormat:@"\t%@\n", stmt];
        }
    }
    [out appendString:@"}>"];
    return out;
}

- (OFString *)invokeName
{
    return [OFString stringWithFormat:@"%@[%@ %@]", _type==kTQClassMethod ? @"+" : @"-", _class.name, [self selector]];
}

- (OFString *)selector
{
    OFMutableString *selector = [OFMutableString string];
    for(TQNodeMethodArgumentDef *arg in self.arguments) {
        if([arg.name isEqual:@"__blk"] || [arg.name isEqual:@"self"])
            continue;
        if(arg.selectorPart)
            [selector appendString:arg.selectorPart];
        if(arg.name)
            [selector appendString:@":"];
    }
    return selector;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(TQError **)aoErr
{
    TQAssertSoft(NO, kTQGenericErrorDomain, kTQGenericError, NULL, @"Methods require their class to be passed to generate code.");
    return NULL;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                 class:(TQNodeClass *)aClass
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(TQError **)aoErr
{
    _class = aClass;
    // If a matching bridged method is found, use the types from there
    OFString *bridgedEncoding;
    if(_type == kTQInstanceMethod)
        bridgedEncoding = [[aProgram.objcParser classNamed:aClass.superClassName] typeForInstanceMethod:[self selector]];
    else
        bridgedEncoding = [[aProgram.objcParser classNamed:aClass.superClassName] typeForClassMethod:[self selector]];

    if(bridgedEncoding && *[bridgedEncoding UTF8String] == _C_VOID) // No such thing as a void return in tranquil
        _retType = @"@";
    else
        _retType = bridgedEncoding;
    _argTypes = [OFMutableArray new];
    OFString *methodSignature;
    if(bridgedEncoding) {
        methodSignature = bridgedEncoding;
        [_argTypes addObject:@"@"]; // __blk
        [_argTypes addObject:@"@"]; // self
        __block int i = 0;
        TQIterateTypesInEncoding([bridgedEncoding UTF8String], ^(const char *type, unsigned long size, unsigned long align, BOOL *stop) {
            if(i++ <= 2) // Skip over the return, self & selector types
                return;
            [_argTypes addObject:[OFString stringWithUTF8String:type]];
        });
    } else {
        methodSignature = [OFMutableString stringWithString:@"@@:"];
        for(TQNodeMethodArgumentDef *argDef in self.arguments) {
            [_argTypes addObject:@"@"];
            if(!argDef.name || [argDef.name isEqual:@"__blk"] || [argDef.name isEqual:@"self"])
                continue;
            [(OFMutableString*)methodSignature appendString:@"@"];
        }
    }

    Value *block = [super generateCodeInProgram:aProgram block:aBlock root:aRoot error:aoErr];
    if(*aoErr)
        return NULL;
    IRBuilder<> *builder = aBlock.builder;

    Value *imp = builder->CreateCall(aProgram.imp_implementationWithBlock, block);
    Value *signature = [aProgram getGlobalStringPtr:methodSignature inBlock:aBlock];
    Value *selector = builder->CreateCall(aProgram.sel_registerName, [aProgram getGlobalStringPtr:[self selector] inBlock:aBlock]);

    Value *classPtr = aClass.classPtr;
    if(_type == kTQClassMethod)
        classPtr = builder->CreateCall(aProgram.object_getClass, classPtr);
    builder->CreateCall4(aProgram.class_replaceMethod, classPtr, selector, imp, signature);

    // If we have parameters with a default argument then we need to create dummy methods to handle that
    unsigned long firstDefArgParamIdx = OF_NOT_FOUND;
    for(int i = 0; i < [self.arguments count]; ++i) {
        if([[self.arguments  objectAtIndex:i] defaultArgument] != nil) {
            firstDefArgParamIdx = i;
            break;
        }
    }
    if(firstDefArgParamIdx != OF_NOT_FOUND) {
        OFArray *argDefs = [self.arguments objectsInRange:(of_range_t){0, firstDefArgParamIdx}];
        for(int i = firstDefArgParamIdx; i < [self.arguments count]; ++i) {
            TQNodeMethod *method = [[self class] nodeWithType:_type];
            method.isCompactBlock = YES;
            method.arguments = [[argDefs mutableCopy] autorelease];

            // Construct a call to the actual method passing nothings
            OFMutableArray *args = [OFMutableArray array];
            for(int j = 2; j < [self.arguments count]; ++j) {
                TQNodeMethodArgumentDef *def = [self.arguments objectAtIndex:j];
                TQNode *passedNode = (j >= i) ? [TQNodeNothing node] : [TQNodeVariable nodeWithName:def.name];
                [args addObject:[TQNodeArgument nodeWithPassedNode:passedNode selectorPart:def.selectorPart]];
            }
            TQNodeMessage *msg = [TQNodeMessage nodeWithReceiver:[TQNodeSelf node]];
            msg.arguments = args;
            [method.statements addObject:msg];
            [method generateCodeInProgram:aProgram block:aBlock class:aClass root:aRoot error:aoErr];

            argDefs = [argDefs arrayByAddingObject:[self.arguments objectAtIndex:i]];
        }
    }

    _class = nil;
    return NULL;
}

@end
