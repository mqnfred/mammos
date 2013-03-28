extern kmain
global start


start:
    mov     esp, 0x200000
    jmp     kmain
