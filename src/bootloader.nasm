; mammos bootloader

; boot index (BIOS drops this MBR at this address)
%define BOOT    0x7c00

; address of stored data (right after IVT and BDA)
%define DATA    0x500

; stack index (right below this MBR)
%define STACK   BOOT - 0xf

; address to the first partition entry in the partition table
%define PART    BOOT + 0x1be

; address at which store temporarily the chunks of kernel
%define CHUNK   0x7e00

; address of the kernel entry point
%define KERNEL  0x100000



ORG 0x7c00
BITS 16



entry:
    ; force the cs:ip
    jmp     0x0000:main



main:
    ; setup the stack and enter unreal with %es (4GB limit)
    mov     sp, STACK
    call    unreal_mode

    ; store the disk number, test lba availability on the bios
    ; and make sure that the first partition starts before 32MB on the disk
    mov     [DATA], dl
    call    test_lba
    call    test_partitionning

    ; load and jump to the kernel in protected mode
    call    load_kernel
    call    jump_kernel
    ;call    trigger_error



unreal_mode:
    ; save flags, disable interrupts, load gdt infos, save %es base address
    pushfd
    push    es
    cli
    lgdt    [gdt_info]

    ; switch to pmode
    mov     eax, cr0
    or      al, 1
    mov     cr0, eax

    ; load the segment selector into %es
    mov     bx, 0x8
    mov     es, bx

    ; switch from pmode
    mov     eax, cr0
    and     al, 0xfe
    mov     cr0, eax

    ; restore flags, es base address, and leave
    pop     es
    popfd
    ret



test_lba:
    ; setup arguments
    mov     ah, 0x41
    mov     dl, byte [DATA]
    mov     bx, 0x55aa

    ; execute test and leave
    int     0x13
    cmp     bx, 0xaa55
    jne     trigger_error
    ret



test_partitionning:
    ; test if the first partition offset is >32MB
    ; in such a case the LBA handling requires 2 16 bit registers
    ; which is not supported atm
    mov     ax, [PART + 10]
    cmp     ax, 0
    jne     trigger_error

    ; test if the entry is valid (total sectors != 0)
    mov     ax, [PART + 12]
    cmp     ax, 0
    jne     good
    mov     ax, [PART + 14]
    cmp     ax, 0
    je      trigger_error

    good:
    ret



load_kernel:
    ; prepare Disk Address Packet (DAP)
    mov     byte [DATA + 2], 0x10
    mov     byte [DATA + 3], 0x00
    mov     word [DATA + 4], 0x0001
    mov     dword [DATA + 6], CHUNK
    mov     dword [DATA + 14], 0x00000000
    mov     word [DATA + 12], 0x0000

    ; prepare constants
    mov     dl, byte [DATA]
    mov     bx, 0x1
    mov     edi, KERNEL

    copy_loop:
    ; retrieve the chunk from the disk
    mov     ah, 0x42
    mov     si, DATA + 2
    mov     word [DATA + 10], bx
    int     0x13

    ; copy that chunk at index KERNEL
    mov     cx, 0x200
    mov     esi, CHUNK
    a32     rep movsb

    inc     bx
    cmp     bx, word [PART + 8]
    jne     copy_loop
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
    jmp     KERNEL



trigger_error:
    ; setup arguments
    mov     ah, 0xe
    mov     bh, 0x1
    mov     bx, error_msg

    ; print the string
    print_loop:
    cmp     byte [bx], 0x0
    je      halt

    mov     al, [bx]
    int     0x10
    add     bx, 1
    jmp     print_loop

    ; stall after printing (busy-wait)
    halt:
    hlt
    jmp     halt



error_msg:
    db      "an error occurred", 0xa, 0xd, 0x0



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
