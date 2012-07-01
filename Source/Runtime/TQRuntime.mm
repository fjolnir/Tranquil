#import "TQRuntime.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>


static const NSString *_TQDynamicIvarTableKey = @"TQDynamicIvarTableKey";

struct TQBlock_byref {
	void *isa;
	struct TQBlock_byref *forwarding;
	int flags;
	int size;
	void (*byref_keep)(struct TQBlock_byref *dst, struct TQBlock_byref *src);
	void (*byref_destroy)(struct TQBlock_byref *);
	id capture;
};

#pragma mark - Utilities

// Hack from libobjc, allows tail call optimization for objc_msgSend
extern id _objc_msgSend_hack(id, SEL) asm("_objc_msgSend");

id TQRetainObject(id obj)
{
	return _objc_msgSend_hack(obj, @selector(retain));
}

id TQReleaseObject(id obj)
{
	return _objc_msgSend_hack(obj, @selector(release));
}

id TQAutoreleaseObject(id obj)
{
	return _objc_msgSend_hack(obj, @selector(autorelease));
}

id TQRetainAutoreleaseObject(id obj)
{
	return TQAutoreleaseObject(TQRetainObject(obj));
}

id TQStoreStrongInByref(void *dstPtr, id obj)
{
	struct TQBlock_byref *dst = (struct TQBlock_byref *)dstPtr;
	id prev = dst->forwarding->capture;
	if(prev == obj)
		return prev;
	TQRetainObject(obj);
	dst->forwarding->capture = obj;
	TQReleaseObject(prev);

	return obj;
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
		// TODO: Use the type encoding to unbox values if necessary
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
		return TQAutoreleaseObject(_objc_msgSend_hack(obj, @selector(copy)));
	return TQRetainAutoreleaseObject(obj);
}

#pragma mark - Operators

BOOL TQAugmentClassWithOperators(Class klass)
{
	// ==
	IMP imp = imp_implementationWithBlock(^(id a, id b) { return [a isEqual:b] ? @YES : @NO; });
	SEL sel = sel_registerName("==:");
	class_addMethod(klass, sel, imp, "@@:@");
	// !=
	imp = imp_implementationWithBlock(^(id a, id b)     { return [a isEqual:b] ? @NO : @YES; });
	sel = sel_registerName("==:");
	class_addMethod(klass, sel, imp, "@@:@");

	// + (Unimplemented by default)
	imp = imp_implementationWithBlock(^(id a, id b) { return [a add:b]; });
	sel = sel_registerName("+:");
	class_addMethod(klass, sel, imp, "@@:@");
	// - (Unimplemented by default)
	imp = imp_implementationWithBlock(^(id a, id b) { return [a subtract: b]; });
	sel = sel_registerName("-:");
	class_addMethod(klass, sel, imp, "@@:@");
	// unary - (Unimplemented by default)
	imp = imp_implementationWithBlock(^(id a)       { return [a negate]; });
	sel = sel_registerName("-");
	class_addMethod(klass, sel, imp, "@@:");

	// * (Unimplemented by default)
	imp = imp_implementationWithBlock(^(id a, id b) { return [a multiply:b]; });
	sel = sel_registerName("*:");
	class_addMethod(klass, sel, imp, "@@:@");
	// / (Unimplemented by default)
	imp = imp_implementationWithBlock(^(id a, id b) { return [a divide:b]; });
	sel = sel_registerName("/:");
	class_addMethod(klass, sel, imp, "@@:@");

	// <
	imp = imp_implementationWithBlock(^(id a, id b) { return ([a compare:b] == NSOrderedAscending) ? @YES : @NO; });
	sel = sel_registerName("<:");
	class_addMethod(klass, sel, imp, "@@:@");
	// >
	imp = imp_implementationWithBlock(^(id a, id b) { return ([a compare:b] == NSOrderedDescending) ? @YES : @NO; });
	sel = sel_registerName("<:");
	class_addMethod(klass, sel, imp, "@@:@");
	// <=
	imp = imp_implementationWithBlock(^(id a, id b) { return ([a compare:b] != NSOrderedDescending) ? @YES : @NO; });
	sel = sel_registerName("<:");
	class_addMethod(klass, sel, imp, "@@:@");
	// >=
	imp = imp_implementationWithBlock(^(id a, id b) { return ([a compare:b] != NSOrderedAscending) ? @YES : @NO; });
	sel = sel_registerName("<:");
	class_addMethod(klass, sel, imp, "@@:@");


	// []
	imp = imp_implementationWithBlock(^(id a, id key)         { return [a valueForKey:key]; });
	sel = sel_registerName("[]:");
	class_addMethod(klass, sel, imp, "@@:@");
	// []=
	imp = imp_implementationWithBlock(^(id a, id key, id val) { return [a setValue:val forKey:key]; });
	sel = sel_registerName("[]=::");
	class_addMethod(klass, sel, imp, "@@:@@");

	return YES;
}
