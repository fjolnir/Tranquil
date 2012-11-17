#ifndef _TQ_PROGRAM_H_
#define _TQ_PROGRAM_H_

#import <Foundation/Foundation.h>
#import <Tranquil/Runtime/TQRuntime.h>

#ifdef __cplusplus
#define TQ_EXTERN_C extern "C"
#else
#define TQ_EXTERN_C
#endif

@class TQHeaderParser, TQNodeBlock;

TQ_EXTERN_C NSString * const kTQSyntaxErrorException;
typedef id (^TQErrorHandlingBlock)(id err);

@interface TQProgram : TQObject {
    BOOL _initializedTQRuntime;

    // Values used for globals under JIT compilation
    struct TQBlockByRef _argGlobalForJIT;
    dispatch_queue_t _globalQueueForJIT;

    // Keeps track of selector globals under AOT
    NSMutableDictionary *_selectorSymbols;
}

@property(readwrite, retain) NSString *name;
@property(readwrite, retain) NSPointerArray *arguments;
@property(readonly) NSMutableDictionary *globals;
@property(readonly) TQHeaderParser *objcParser;
@property(readwrite) BOOL shouldShowDebugInfo;

// Search path related
@property(readwrite, retain) NSMutableArray *searchPaths, *allowedFileExtensions;
// AOT compilation related
@property(readwrite, retain) NSString *outputPath;
@property(readwrite) BOOL useAOTCompilation;
@property(readwrite) TQArchitecture targetArch;

#pragma mark - Methods

+ (TQProgram *)sharedProgram;
+ (TQProgram *)programWithName:(NSString *)aName;
- (id)initWithName:(NSString *)aName;
- (id)executeScriptAtPath:(NSString *)aPath error:(NSError **)aoErr;
- (id)executeScriptAtPath:(NSString *)aScript onError:(TQErrorHandlingBlock)aHandler;
- (id)executeScript:(NSString *)aScript error:(NSError **)aoErr;
- (id)executeScript:(NSString *)aScript onError:(TQErrorHandlingBlock)aHandler;
@end
#endif
