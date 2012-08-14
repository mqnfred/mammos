; the stage2 code is contained in the Extended Boot Record (EBR)
%include "src/bootloader/linking.nasm"


ORG 0x7e00
BITS 16



s:tage2:
    ; load kernel
    call    load_kernel

    ; switch to protected mode and jump into the kernel
    call    jump_kernel



load_kernel:
    ; setup constant arguments, clearing direction flag
    mov     ah, 0x42
    mov     dl, byte [BOOT_DISK]
    mov     bx, KERNEL_SIZE / SECTOR_SIZE / CHUNK_SIZE
    mov     edi, KERNEL_OFFSET
    cld

    loading_loop:
    ; setup Disk Address Packet (DAP) in the stack
    push    0x0000
    push    0x0000
    push    0x0000
    push    word [BOOT_LBA]
    push    0x0000
    push    CHUNK_OFFSET
    push    CHUNK_SIZE
    push    0x0010

    ; read into the chunk space and reset %sp to its previous value
    ; popping would be useless, we do not need the current DAP values anymore
    ; 0x10 is the size of the DAP packet pushed in the stack
    mov     si, sp
    int     0x13
    add     sp, 0x10

    ; move the chunk to its place at KERNEL_OFFSET
    mov     cx, CHUNK_SIZE * SECTOR_SIZE
    mov     esi, CHUNK_OFFSET
    a32 rep movsb

    ; continue if there are still chunks to be read
    sub     bx, 1
    cmp     bx, 0
    jne     loading_loop
    ret



jump_kernel:
    ; disable interrupts and load gdt
    cli
    lgdt    [gdt_info]

    ; actual switch to protected mode and leave the routine
    mov     eax, cr0
    or      al, 1
    mov     cr0, eax

    ; set the CS register
    jmp     0x8:pmode

    BITS 32
    pmode:
    jmp     KERNEL_OFFSET



gdt_info:
    dw      gdt_end - gdt - 1
    dd      gdt



gdt:
    ; null segment
    dd      0x0, 0x0

    ; kernel cs
    db      0xff, 0xff, 0x00, 0x00, 0x00, 10011010b, 11001111b, 0x00

    ; kernel ds
    db      0xff, 0xff, 0x00, 0x00, 0x00, 10010010b, 11001111b, 0x00

    ; tss
    dd      0x0, 0x0
gdt_end:
