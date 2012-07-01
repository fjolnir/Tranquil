#ifndef _TQ_PROGRAM_H_
#define _TQ_PROGRAM_H_

#include <Foundation/Foundation.h>
#include "TQNode.h"

#include <llvm/Module.h>

@interface TQProgram : NSObject {
	llvm::Module *_module;
}
@property(readwrite, retain) NSString *name;
@property(readwrite, retain) TQNodeBlock *root;

+ (TQProgram *)programWithName:(NSString *)aName;
- (id)initWithName:(NSString *)aName;
- (BOOL)run;
@end

#endif
