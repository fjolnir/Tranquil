#include <arm/arch.h>

#ifdef _ARM_ARCH_7
#define THUMB 1
#endif

.syntax unified

#if defined(__DYNAMIC__)
#define Extern(var) \
    .non_lazy_symbol_pointer                        ;\
L ## var ## __non_lazy_ptr:                         ;\
    .indirect_symbol var                            ;\
    .long 0
#else
#define Extern(var) \
    .globl var
#endif

#if defined(__DYNAMIC__) && defined(THUMB)
#define GetExternalAddress(reg,var)                  \
    ldr reg, 4f                                     ;\
3:  add reg, pc                                     ;\
    ldr reg, [reg]                                  ;\
    b   5f                                          ;\
.align 2                                            ;\
4:  .long   L ## var ## __non_lazy_ptr - (3b + 4)   ;\
5:
#elif defined(__DYNAMIC__)
#define GetExternalAddress(reg,var)                  \
    ldr     reg, 4f                                 ;\
3:  ldr     reg, [pc, reg]                          ;\
    b       5f                                      ;\
   .align 2                                         ;\
4: .long   L ## var ## __non_lazy_ptr - (3b + 8)    ;\
5:
#else
#define GetExternalAddress(reg,var)                  \
    ldr     reg, 3f                                 ;\
    b       4f                                      ;\
    .align 2                                        ;\
3:  .long var                                       ;\
4:
#endif

#if defined(__DYNAMIC__)
#define BranchExternal(var)  \
    GetExternalAddress(ip, var)                     ;\
    bx ip
#else
#define BranchExternal(var)                          \
    b var
#endif

#if defined(__DYNAMIC__) && defined(THUMB)
#define CallExternal(var)                            \
    GetExternalAddress(ip,var)                      ;\
    blx ip
#elif defined(__DYNAMIC__)
#define CallExternal(var)                            \
    GetExternalAddress(ip,var)                      ;\
    MOVE lr, pc                                     ;\
    bx   ip
#else
#define CallExternal(var)                            \
    bl var
#endif



.macro SaveArgs
    stmfd sp!, {a1-a4, r7, lr}
.endmacro
.macro RestoreArgs
    ldmfd sp!, {a1-a4, r7, lr}
.endmacro

.macro Entry /* name */
    .text
#ifdef THUMB
    .thumb
#endif
    .align 5
    .globl    _$0
#ifdef THUMB
    .thumb_func
#endif
    _$0:
.endmacro

Extern(_objc_msgSend)
Extern(_tq_boxedMsgSend)
Extern(__TQSelectorCacheLookup)
Extern(__TQCacheSelector)
Extern(_TQGlobalNil)

Entry tq_msgSend_noBoxing
    teq a1, #0
    beq nilSend
    BranchExternal(_objc_msgSend)

Entry tq_msgSend
    teq a1, #0
    beq nilSend
    // Save the argument registers
    SaveArgs
    CallExternal(__TQSelectorCacheLookup)
    teq r0, #1
    beq normalSend
    teq r0, #0
    bne boxedSend

    // Restore arguments and cache the selector
    RestoreArgs
    SaveArgs
    CallExternal(__TQCacheSelector)
    RestoreArgs
    b _tq_msgSend // Retry

.align 2
normalSend:
    RestoreArgs
    BranchExternal(_objc_msgSend)

.align 2
boxedSend:
    RestoreArgs
    BranchExternal(_tq_boxedMsgSend)

.align 2
nilSend:
    GetExternalAddress(a1, _TQGlobalNil)
    ldr a1, [a1]
    BranchExternal(_objc_msgSend)
