#import <ffi.h>
#import <Tranquil/Runtime/TQObject.h>
#import <Tranquil/Shared/TQBatching.h>

@interface TQFFIType : TQObject {
    OFMutableArray *_referencedTypes;
    TQ_BATCH_IVARS
}
@property(readonly) const char *encoding;
@property(readonly) ffi_type *ffiType;

+ (ffi_type *)scalarTypeToFFIType:(const char *)aType;
+ (TQFFIType *)typeWithEncoding:(const char *)aEncoding;
+ (TQFFIType *)typeWithEncoding:(const char *)aEncoding nextType:(const char **)aoNextType;
- (id)initWithEncoding:(const char *)aEncoding nextType:(const char **)aoNextType;
@end

