#import <ObjFW/ObjFW.h>

@class TQNumber;

@interface OFString (Tranquil)
- (OFString *)substringToIndex:(size_t)aIdx;
- (OFString *)substringFromIndex:(size_t)aIdx;
- (OFString *)stringByCapitalizingFirstLetter;
- (TQNumber *)toNumber;
- (OFMutableString *)multiply:(TQNumber *)aTimes;
- (OFMutableString *)add:(id)aObj;
- (char)charValue;
- (OFString *)pathExtension;
- (OFString *)stringByDeletingPathExtension;
- (OFString *)stringByAppendingPathExtension:(NSString *)ext;
@end

@interface OFMutableString (Tranquil)
@end
