#import "TQNodeBlock.h"
#include <llvm/Support/IRBuilder.h>

@interface TQNodeIfBlock : TQNodeBlock
@property(readwrite, retain) TQNode *condition;
@property(readwrite, copy) NSMutableArray *elseBlockStatements;

+ (TQNodeIfBlock *)node;
@end
