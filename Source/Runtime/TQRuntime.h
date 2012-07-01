// These implement support for dynamic instance variables
id TQValueForKey(id obj, char *key);
void TQSetValueForKey(id obj, char *key, id value);

bool TQObjectIsStackBlock(id obj);
id TQPrepareObjectForReturn(id obj);
