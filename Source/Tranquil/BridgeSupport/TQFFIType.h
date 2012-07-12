#import <ffi/ffi.h>
#import <Foundation/Foundation.h>

@interface TQFFIType : NSObject {
    NSMutableArray *_referencedTypes;
}
@property(readonly) const char *encoding;
@property(readonly) ffi_type *ffiType;
@property(readonly) NSUInteger size;
+ (ffi_type *)scalarTypeToFFIType:(const char *)aType;
+ (TQFFIType *)typeWithEncoding:(const char *)aEncoding;
+ (TQFFIType *)typeWithEncoding:(const char *)aEncoding nextType:(const char **)aoNextType;
- (id)initWithEncoding:(const char *)aEncoding nextType:(const char **)aoNextType;
@end

