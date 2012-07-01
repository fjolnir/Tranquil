#import "TQRuntime.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>


static const NSString *_TQDynamicIvarTableKey = @"TQDynamicIvarTableKey";

#pragma mark - Utilities

// Hack from libobjc, allows tail call optimization for objc_msgSend
extern id _objc_msgSend_hack(id, SEL) asm("_objc_msgSend");

static inline id _retainObject(id obj)
{
	return _objc_msgSend_hack(obj, @selector(autorelease));
}

static inline id _releaseObject(id obj)
{
	return _objc_msgSend_hack(obj, @selector(release));
}

static inline id _autoreleaseObject(id obj)
{
	return _objc_msgSend_hack(obj, @selector(autorelease));
}

static inlien id _retainAutoreleaseObject(id obj)
{
	return _autoreleaseObject(_retainObject(obj));
}

#pragma mark - Dynamic instance variables

static inline NSMapTable *_TQGetDynamicIvarTable(id obj)
{
	NSMapTable *ivarTable = objc_getAssociatedObject(obj, _TQDynamicIvarTableKey);
	if(!ivarTable) {
		ivarTable = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
		objc_setAssociatedObject(obj, _TQDynamicIvarTableKey, ivarTable, OBJC_ASSOCIATION_RETAIN);
	}
	return ivarTable;
}

static inline size_t _accessorNameLen(const char *accessorNameLoc)
{
	size_t accessorNameLen = 0;
	const char *accessorNameEnd = strstr(accessorNameLoc, ",");
	if(!accessorNameEnd)
		return strlen(accessorNameLoc);
	else
		return accessorNameEnd - accessorNameLoc;
}

id TQValueForKey(id obj, char *key)
{
	if(!obj)
		return nil;
	objc_property_t property = class_getProperty(object_getClass(obj), key);
	if(property) {
		// TODO: Use the type encoding to box values if necessary
		const char *attrs = property_getAttributes(property);
		char *getterNameLoc = strstr(attrs, ",S");
		if(!getterNameLoc) {
			// Standard getter
			return objc_msgSend(obj, sel_registerName(key));
		} else {
			// Custom getter
			char getterName[_accessorNameLen(getterNameLoc)];
			strcpy(getterName, getterNameLoc);
			return objc_msgSend(obj, sel_registerName(getterName));
		}
	} else {
		NSMapTable *ivarTable = _TQGetDynamicIvarTable(obj);
		return (id)NSMapGet(ivarTable, key);
	}
}

void TQSetValueForKey(id obj, char *key, id value)
{
	if(!obj)
		return;
	objc_property_t property = class_getProperty(object_getClass(obj), key);
	if(property) {
		// TODO: Use the type encoding to do unbox values if necessary
		const char *attrs = property_getAttributes(property);
		char *setterNameLoc = strstr(attrs, ",S");
		if(!setterNameLoc) {
			// Standard setter
			size_t setterNameLen = 3 + strlen(key);
			char setterName[setterNameLen];
			strcpy(setterName, "set");
			strcpy(setterName + 3, key);
			objc_msgSend(obj, sel_registerName(setterName), value);
		} else {
			// Custom setter
			char setterName[_accessorNameLen(setterNameLoc)];
			strcpy(setterName, setterNameLoc);
			objc_msgSend(obj, sel_registerName(setterName), value);
		}
	} else {
		NSMapTable *ivarTable = _TQGetDynamicIvarTable(obj);
		NSMapInsert(ivarTable, key, value);
	}
}

#pragma mark -

bool TQObjectIsStackBlock(id obj)
{
	return obj != nil && *(void**)obj == _NSConcreteStackBlock;
}

id TQPrepareObjectForReturn(id obj)
{
	if(TQObjectIsStackBlock(obj))
		return _autoreleaseObject((id)_Block_copy(obj));
	return _retainAutoreleaseObject(obj);
}
