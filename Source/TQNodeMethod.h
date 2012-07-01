#import "TQNode.h"
#import "TQNodeBlock.h"

typedef enum {
	kTQClassMethod,
	kTQInstanceMethod
} TQMethodType;

// A method definition (+ aMethod: argument { body })
@interface TQNodeMethod : TQNodeBlock
@property(readwrite, assign) TQMethodType type;
+ (TQNodeMethod *)node;
+ (TQNodeMethod *)nodeWithType:(TQMethodType)aType;
- (id)initWithType:(TQMethodType)aType;
@end
