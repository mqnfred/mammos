global div_zero_exception
div_zero_exception:
    ; save registers
    pushad
    push    gs
    push    fs
    push    es
    push    ds

    ; whatver

    ; restore registers and leave
    pop     ds
    pop     es
    pop     fs
    pop     gs
    popad
    iret



global page_fault_exception
page_fault_exception:
    ; save registers
    pushad
    push    gs
    push    fs
    push    es
    push    ds

    ; whatver

    ; restore registers and leave
    pop     ds
    pop     es
    pop     fs
    pop     gs
    popad
    iret
