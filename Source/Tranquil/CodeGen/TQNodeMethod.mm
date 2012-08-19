#import "TQNodeMethod.h"
#import "TQNodeMessage.h"
#import "TQNodeArgument.h"
#import "TQNodeClass.h"
#import "TQProgram.h"
#import "../Shared/TQDebug.h"
#import "TQNodeArgumentDef.h"
#import "TQNodeOperator.h"
#import "TQNodeVariable.h"

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
    [self addArgument:[TQNodeMethodArgumentDef nodeWithName:@"__blk"] error:nil];
    [self addArgument:[TQNodeMethodArgumentDef nodeWithName:@"self"] error:nil];


    return self;
}

- (id)init
{
    return [self initWithType:kTQInstanceMethod];
}

- (BOOL)addArgument:(TQNodeMethodArgumentDef *)aArgument error:(NSError **)aoErr
{
    if(self.arguments.count == 2)
        TQAssertSoft(aArgument.selectorPart != nil,
                     kTQSyntaxErrorDomain, kTQUnexpectedIdentifier, NO,
                     @"No name given for method");
    [self.arguments addObject:aArgument];

    return YES;
}

- (NSString *)description
{
    NSMutableString *out = [NSMutableString stringWithString:@"<meth@ "];
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

- (NSString *)_invokeName
{
    return [NSString stringWithFormat:@"%@[%@ %@]", _type==kTQClassMethod ? @"+" : @"-", _class.name, [self selector]];
}

- (NSString *)selector
{
    NSMutableString *selector = [NSMutableString string];
    for(TQNodeMethodArgumentDef *arg in self.arguments) {
        if([arg.name isEqualToString:@"__blk"] || [arg.name isEqualToString:@"self"])
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
                                 error:(NSError **)aoErr
{
    TQAssertSoft(NO, kTQGenericErrorDomain, kTQGenericError, NULL, @"Methods require their class to be passed to generate code.");
    return NULL;
}

- (llvm::Value *)generateCodeInProgram:(TQProgram *)aProgram
                                 block:(TQNodeBlock *)aBlock
                                 class:(TQNodeClass *)aClass
                                  root:(TQNodeRootBlock *)aRoot
                                 error:(NSError **)aoErr
{
    _class = aClass;
    // If a matching bridged method is found, use the types from there
    NSString *bridgedEncoding;
    if(_type == kTQInstanceMethod)
        bridgedEncoding = [[aProgram.objcParser classNamed:aClass.superClassName] typeForInstanceMethod:[self selector]];
    else
        bridgedEncoding = [[aProgram.objcParser classNamed:aClass.superClassName] typeForClassMethod:[self selector]];

    if(bridgedEncoding && *[bridgedEncoding UTF8String] == _C_VOID) // No such thing as a void return in tranquil
        _retType = @"@";
    else
        _retType = bridgedEncoding;
    _argTypes = [[NSMutableArray arrayWithCapacity:self.arguments.count] retain];
    NSString *methodSignature;
    if(bridgedEncoding) {
        methodSignature = bridgedEncoding;
        [_argTypes addObject:@"@"]; // __blk
        [_argTypes addObject:@"@"]; // self
        __block int i = 0;
        TQIterateTypesInEncoding([bridgedEncoding UTF8String], ^(const char *type, NSUInteger size, NSUInteger align, BOOL *stop) {
            if(i++ <= 2) // Skip over the return, self & selector types
                return;
            [_argTypes addObject:[NSString stringWithUTF8String:type]];
        });
    } else {
        methodSignature = [NSMutableString stringWithString:@"@@:"];
        for(int i = 1; i < self.arguments.count+1; ++i) {
            [_argTypes addObject:@"@"];
            [(NSMutableString*)methodSignature appendString:@"@"];
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

    _class = nil;
    return NULL;
}

@end
