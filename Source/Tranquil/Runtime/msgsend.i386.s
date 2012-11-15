// tq_msgSend minus the boxing support, but still with nil responder support
.globl _tq_msgSend_noBoxing
_tq_msgSend_noBoxing:
    movl 4(%esp), %eax
    testl %eax, %eax
    je nilSend
    jmp _objc_msgSend

// tq_msgSend: inspects a method and either redirects to objc_msgSend or tq_boxedMsgSend depending on it's signature
.globl _tq_msgSend
_tq_msgSend:
    movl 4(%esp), %eax
    testl %eax, %eax
    je nilSend

    pushl %ebp
    movl %esp, %ebp
    subl $8, %esp

    movl 8(%ebp),  %eax // self
    movl 12(%ebp), %edx // selector
    movl %eax,  (%esp)
    movl %edx, 4(%esp)
    call __TQSelectorCacheLookup

    cmp $1, %eax  // Value 0x1 means it's a safe method and we can simply objc_msgSend
    je  normalSend
    cmp $0, %eax  // Other non-null value means it requires boxing
    jne boxedSend

    // Otherwise the method has not been processed yet
    call __TQCacheSelector
    addl $8, %esp
    // Try again
    popl %ebp
    jmp _tq_msgSend

normalSend:
    addl $8, %esp
    popl %ebp
    jmp _objc_msgSend
boxedSend:
    addl $8, %esp
    popl %ebp
    jmp _tq_boxedMsgSend
nilSend:
    // Load the nil receiver
    movl _TQGlobalNil(%eip), %eax
    movl %eax, 4(%esp)
    jmp _objc_msgSend
