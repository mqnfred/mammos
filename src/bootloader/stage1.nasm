; stage1, stored in the MBR
; for more information, see the /design.md file

%define STAGE1_ENTRY    0x7c00

%define STAGE2_ENTRY    0x7e00
%define STAGE2_SIZE     61

%define STACK_BASE      0x7bf0

ORG STAGE1_ENTRY
BITS 16



stage1_entry:
    ; check BIOS Logical Block Addressing (LBA) availability
    call    check_lba

    ; first, enter unreal mode with %es only (for later use with rep movsb...)
    call    enter_unrealmode

    ; second, setup the stack in a tidy place (right below MBR in linear mem)
    mov     sp, STACK_BASE

    ; third, retrieve information about the drive on which the OS is running
    call    disk_infos

    ; fourth, load the stage2 binary, located in the EBR (from sectors 2 to
    ; sector 63, 61 sectors wide)
    call    load_stage2

    ; fifth, jump into the stage2
    jmp     STAGE2_ENTRY




check_lba:
    mov     ah, 0x41
    mov     bx, 0x55aa
    int     0x13
    cmp     bx, 0xaa55
    jne     stall
    ret



enter_unrealmode:
    ; save flags, %es base address, ignore IRQs and load the gdt
    push    es
    pushfd
    cli
    lgdt    [gdtdesc]

    ; enter protected mode
    mov     eax, cr0
    or      al, 1
    mov     cr0, eax

    ; load the %es segment register with the entry in the gdt at index 0x8
    mov     bx, 0x8
    mov     es, bx

    ; exit protected mode
    mov     eax, cr0
    and     al, 0xfe
    mov     cr0, eax

    ; restore flags, %es base address and return
    popfd
    pop     es
    ret



disk_infos:
    ; save the return address (this is called)
    pop     ax

    ; first, find the bootable partition entry address
    ; start at entry -1 (see why below)
    mov     bx, STAGE1_ENTRY + 0x1be - 0x10

    loop:
    ; next entry index and test
    add     bx, 0x10
    cmp     byte [bx], 0x80
    je      found

    ; test index and leave/go on to next entry
    cmp     bx, STAGE1_ENTRY + 0x1ee
    je      stall

    ; test if partition is old minix (code 0x80)
    found:
    cmp     byte [bx + 4], 0x80
    jne     stall

    ; push the LBA of the partition contained in %bx as well as %dx (disk nbr)
    ; the lba is a double word, and the stack only pushes words
    push    dx
    push    word [bx + 8]
    push    word [bx + 10]

    ; restore return address
    push    ax



load_stage2:
    ; reset the disk's heads, %dl already contains the disk number
    mov     ah, 0x0
    int     0x13

    ; extended read with infos at ebr_addr and exit if no error, stall otherwise
    mov     ah, 0x42
    mov     si, ebr_addr
    int     0x13
    cmp     ah, 0x00
    jne     stall
    ret



; stall when an error occurs
stall:
    hlt
    jmp     stall



; ----
; DATA
; ----
gdt:
    ; null segment
    db  0x00, 0x00, 0x00, 0x00
    db  0x00, 0x00, 0x00, 0x00

    ; kernel data segment descriptor, used to load %es
    db  0xff, 0xff, 0x00, 0x00
    db  0x00, 0x92, 0xcf, 0x00



gdtdesc:
    dw  gdtdesc - gdt - 1
    dd  gdt



ebr_addr:
    db  0x10, 0x00
    dw  STAGE2_SIZE
    dw  STAGE2_ENTRY, 0x0000 ; little endian!
    dq  0x1 ; first sector after MBR
