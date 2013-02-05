; this is a dummy kernel

ORG 0x100000 ; offset 1MB
BITS 32


kernel_entry:
    hlt
    jmp     kernel_entry
