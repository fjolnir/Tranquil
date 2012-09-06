// Parameter registers
#define a1  rdi
#define a1d edi
#define a1b dil
#define a2  rsi
#define a2d esi
#define a2b sil
#define a3  rdx
#define a3d edx
#define a4  rcx
#define a4d ecx
#define a5  r8
#define a5d r8d
#define a6  r9
#define a6d r9d

// Pushes a stack frame and saves all registers that might contain parameter values.
// On exit:
//     %rsp is 16-byte aligned
.macro SaveRegisters
    enter  $$0x80+8, $$0      // +8 for alignment
    movdqa %xmm0, -0x80(%rbp)
    push   %rax               // might be xmm parameter count
    movdqa %xmm1, -0x70(%rbp)
    push   %a1
    movdqa %xmm2, -0x60(%rbp)
    push   %a2
    movdqa %xmm3, -0x50(%rbp)
    push   %a3
    movdqa %xmm4, -0x40(%rbp)
    push   %a4
    movdqa %xmm5, -0x30(%rbp)
    push   %a5
    movdqa %xmm6, -0x20(%rbp)
    push   %a6
    movdqa %xmm7, -0x10(%rbp)
.endmacro

// Pops a stack frame pushed by SaveRegisters
.macro RestoreRegisters
    movdqa -0x80(%rbp), %xmm0
    pop %a6
    movdqa -0x70(%rbp), %xmm1
    pop %a5
    movdqa -0x60(%rbp), %xmm2
    pop %a4
    movdqa -0x50(%rbp), %xmm3
    pop %a3
    movdqa -0x40(%rbp), %xmm4
    pop %a2
    movdqa -0x30(%rbp), %xmm5
    pop %a1
    movdqa -0x20(%rbp), %xmm6
    pop %rax
    movdqa -0x10(%rbp), %xmm7
    leave
.endmacro

// tq_msgSend minus the boxing support, but still with nil responder support
.globl _tq_msgSend_noBoxing
_tq_msgSend_noBoxing:
    test %a1, %a1
    je nilSend
    jmp _objc_msgSend

// tq_msgSend: inspects a method and either redirects to objc_msgSend or tq_boxedMsgSend depending on it's signature
// TODO: Make sure this is thread safe
.globl _tq_msgSend
_tq_msgSend:
    test %a1, %a1
    je nilSend

    SaveRegisters _tq_msgSend

    call _object_getClass
    xor  %rax, %a2 // klass xor selector -> second param slot
    // Load the global CFDict _TQSelectorCache to first param slot
    mov  __TQSelectorCache@GOTPCREL(%rip), %a1
    mov  (%a1), %a1
    call _CFDictionaryGetValue

    cmp $1, %rax  // Value 0x1 means it's a safe method and we can simply objc_msgSend
    je  normalSend
    cmp $0, %rax  // Other non-null value means it requires boxing
    jne boxedSend

    // Otherwise the method has not been processed yet
    RestoreRegisters
    SaveRegisters
    call __TQCacheSelector
    RestoreRegisters
    // Try again
    jmp _tq_msgSend

normalSend:
    RestoreRegisters
    jmp _objc_msgSend
boxedSend:
    RestoreRegisters
    jmp _tq_boxedMsgSend
nilSend:
    mov  _TQGlobalNil@GOTPCREL(%rip), %a1
    mov  (%a1), %a1
    jmp _objc_msgSend

