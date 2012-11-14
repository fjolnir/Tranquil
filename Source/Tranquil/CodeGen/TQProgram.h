#ifndef _TQ_PROGRAM_H_
#define _TQ_PROGRAM_H_

#import <Tranquil/Runtime/TQRuntime.h>
#import <dispatch/dispatch.h>

#ifdef __cplusplus
#define TQ_EXTERN_C extern "C"
#else
#define TQ_EXTERN_C
#endif

@class TQHeaderParser, TQNodeBlock;

TQ_EXTERN_C OFString * const kTQSyntaxErrorException;

typedef enum {
    kTQArchitectureHost,
    kTQArchitectureI386,
    kTQArchitectureX86_64,
    kTQArchitectureARMv7
} TQArchitecture;

@interface TQProgram : TQObject {
    BOOL _initializedTQRuntime;

    // Values used for globals under JIT compilation
    struct TQBlockByRef _argGlobalForJIT;
    dispatch_queue_t _globalQueueForJIT;
}

@property(readwrite, retain) OFString *name;
@property(readwrite, retain) OFMutableArray *arguments;
@property(readonly) OFMutableDictionary *globals;
@property(readonly) TQHeaderParser *objcParser;
@property(readwrite) BOOL shouldShowDebugInfo;

// Search path related
@property(readwrite, retain) OFMutableArray *searchPaths, *allowedFileExtensions;
// AOT compilation related
@property(readwrite, retain) OFString *outputPath;
@property(readwrite) BOOL useAOTCompilation;
@property(readwrite) TQArchitecture targetArch;

#pragma mark - Methods

+ (TQProgram *)sharedProgram;
+ (TQProgram *)programWithName:(OFString *)aName;
- (id)initWithName:(OFString *)aName;
- (id)executeScriptAtPath:(OFString *)aPath error:(TQError **)aoErr;
- (id)executeScript:(OFString *)aScript error:(TQError **)aoErr;
@end
#endif
