#import "TQNodeBlock.h"
#include <llvm/Support/IRBuilder.h>

@interface TQNodeIfBlock : TQNodeBlock
@property(readwrite, retain) TQNode *condition;

+ (TQNodeIfBlock *)node;
@end
