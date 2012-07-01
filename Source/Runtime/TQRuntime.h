// Tranquil runtime functions

id TQRetainObject(id obj);
id TQReleaseObject(id obj);
id TQAutoreleaseObject(id obj);
id TQRetainAutoreleaseObject(id obj);

// Stores obj in a Block_ByRef, retaining it
id TQStoreStrongInByref(void *dstPtr, id obj);

// These implement support for dynamic instance variables
id TQValueForKey(id obj, char *key);
void TQSetValueForKey(id obj, char *key, id value);

bool TQObjectIsStackBlock(id obj);
id TQPrepareObjectForReturn(id obj);

// Adds operator methods to the passed class (such as ==:, >=:, []: etc)
BOOL TQAugmentClassWithOperators(Class klass);
