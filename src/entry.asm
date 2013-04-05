%define PIC1 0x20
%define PIC2 0xA0
%define ICW1 0x11
%define ICW4 0x1



global flush_gdt
global flush_idt

extern setup_idt
extern setup_gdt
extern setup_mem

extern kmain



global start
start:
    call    setup_gdt
    call    setup_idt
    call    setup_irq

    ; the memory size is a parameter to this (right at %esp)
    ; setup by the custom bootloader
    call    setup_mem

    call    kmain



flush_gdt:
    push    dword ebp
    mov     ebp, esp

    mov     eax, [ebp + 8]
    lgdt    [eax]

    ; setup standart segment selectors
    mov     ax, 0x10
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ss, ax

    ; setup code segment selector
    jmp     0x08:pmode
    pmode:

    mov     esp, ebp
    pop     ebp
    ret



flush_idt:
    push    dword ebp
    mov     ebp, esp

    mov     eax, [ebp + 8]
    lidt    [eax]

    mov     esp, ebp
    pop     ebp
    ret



setup_irq:
    ; send ICW1
    mov     al, ICW1
    out     PIC1, al
    out     PIC2, al

    ; remap pics on the IDT above the 32 reserved exception slots
    mov     al, 0x20
    out     PIC1 + 1, al
    mov     al, 0x28
    out     PIC2 + 1, al

    ; connect slave
    mov     al, 4
    out     PIC1 + 1, al
    mov     al, 2
    out     PIC2 + 1, al

    ; send ICW4 and leave
    mov     al, ICW4
    out     PIC1 + 1, al
    out     PIC2 + 1, al
    ret
