// Tranquil runtime functions

#import <Foundation/Foundation.h>

id TQRetainObject(id obj);
id TQReleaseObject(id obj);
id TQAutoreleaseObject(id obj);
id TQRetainAutoreleaseObject(id obj);

// Stores obj in a Block_ByRef, retaining it
id TQStoreStrongInByref(void *dstPtr, id obj);

// These implement support for dynamic instance variables (But use existing properties if available)
id TQValueForKey(id obj, char *key);
void TQSetValueForKey(id obj, char *key, id value);

BOOL TQObjectIsStackBlock(id obj);
id TQPrepareObjectForReturn(id obj);

// Adds operator methods to the passed class (such as ==:, >=:, []: etc)
BOOL TQAugmentClassWithOperators(Class klass);

extern SEL TQEqOpSel;
extern SEL TQNeqOpSel;
extern SEL TQLTOpSel;
extern SEL TQGTOpSel;
extern SEL TQGTEOpSel;
extern SEL TQLTEOpSel;
extern SEL TQMultOpSel;
extern SEL TQDivOpSel;
extern SEL TQAddOpSel;
extern SEL TQSubOpSel;
extern SEL TQUnaryMinusOpSel;
extern SEL TQSetterOpSel;
extern SEL TQGetterOpSel;
