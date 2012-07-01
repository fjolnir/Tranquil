// Object & basic types

#ifndef _TRANQUIL_H_
#define _TRANQUIL_H_

#include <CoreFoundation/CoreFoundation.h>

#define TQ_NUMTYPE double

typedef struct tq_vm         tq_vm_t;

struct tq_vm {

};

struct tq_stack {

}


void tq_push(tq_vm_t *vm, tq_object_t *object);
void tq_pop(tq_vm_t *vm, unsigned count);

tq_object *tq_object_create();
tq_object *tq_object_set(tq_string *key, tq_object *value);
tq_object *tq_object_get(tq_string *key);

tq_object *tq_retain(tq_object *obj);
void tq_release(tq_object *obj);
#endif
