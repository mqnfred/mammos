%define PIC1        (0x20)
%define PIC2        (0xA0)
%define ICW1        (0x11)
%define ICW4        (0x1)
%define PAGE_SIZE   (0x1000)



global flush_gdt
global flush_idt
extern freemem_offset
extern setup_heap
extern setup_frames
extern setup_paging
extern setup_idt
extern setup_gdt
extern mmap
extern kmain



global start
start:
    call    setup_gdt
    call    setup_idt
    call    setup_irq

    ; the memory size is a parameter to this (right at %esp)
    ; setup by the custom bootloader
    call    setup_mem

    ; setup the stack at the top of memory (grows downward)
    ; mmap the first 4kB right below 4GBytes - 4MBytes since the last 4MBytes
    ; of address space are reserved for page directory recursive mapping
    push    dword 0xFFC00000 - PAGE_SIZE
    call    mmap
    mov     esp, 0xFFC00000

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



setup_mem:
    ; the argument to setup_frames() is the memory size, passed by start()
    push    dword [esp + 4]
    call    setup_frames
    add     esp, 4

    call    setup_paging

    mov     eax, freemem_offset
    push    dword [eax]
    call    setup_heap
    add     esp, 4

    ret
