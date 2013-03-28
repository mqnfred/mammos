global div_zero_exception
div_zero_exception:
    ; save registers
    pushad
    push    gs
    push    fs
    push    es
    push    ds
    push    ss

    ; whatver
    

    ; restore registers and leave
    pop     ss
    pop     ds
    pop     es
    pop     fs
    pop     gs
    popad
    iret
