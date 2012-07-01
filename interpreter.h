// Object & basic types

#ifndef _TRANQUIL_H_
#define _TRANQUIL_H_

#include <CoreFoundation/CoreFoundation.h>

#define TQ_NUMTYPE double

typedef struct tq_vm         tq_vm_t;
typedef struct tq_object     tq_object_t;
typedef struct tq_string     tq_string_t;
typedef struct tq_number     tq_number_t;
typedef struct tq_array      tq_array_t;
typedef struct tq_dictionary tq_dictionary_t;
typedef struct tq_block      tq_block_t;

struct tq_state {

};


struct tq_object {
	long refCount;
	tq_object_t *metaObject;
	CFDictionaryRef members;
	void *data;
};

#define TQ_STR(str) ((tq_string){ 0, CFSTR(str) })
struct tq_string {
	long refCount;
	CFMutableStringRef value;
};

struct tq_number {
	long refCount;
	TQ_NUMTYPE value;
}

struct tq_array {
	long refCount;
	CFMutableArrayRef value;
}

struct tq_dictionary {
	long refCount;
	CFMutableDictionaryRef value;
}

struct tq_block {
	long refCount;
};

void tq_push(tq_vm_t *vm, tq_object_t *object);
void tq_pop(tq_vm_t *vm, unsigned count);

tq_object *tq_object_create();
tq_object *tq_object_set(tq_string *key, tq_object *value);
tq_object *tq_object_get(tq_string *key);

tq_object *tq_retain(tq_object *obj);
void tq_release(tq_object *obj);
#endif
