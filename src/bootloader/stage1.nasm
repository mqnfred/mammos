; stage1, stored in the MBR
; for more information, see the /design.md file

%define STAGE1_ENTRY    0x7c00

%define STAGE2_ENTRY    0x7e00
%define STAGE2_SIZE     61

%define STACK_BASE      0x7bf0

ORG STAGE1_ENTRY
BITS 16



stage1_entry:
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
    je      halt

    ; test if partition is minix (code 0x81)
    found:
    cmp     byte [bx + 4], 0x81
    jne     halt

    ; bx contains the address of a valid partition entry, push it on the stack
    push    dx
    push    bx

    ; restore return address
    push    ax



load_stage2:
    ; reset the disk's heads, %dl already contains the disk number
    mov     ah, 0x0
    int     0x13

    ; load opcode, destination address, stage2 length in sectors
    mov     ah, 0x2
    mov     bx, STAGE2_ENTRY
    mov     al, STAGE2_SIZE

    ; load the disk informations (%dl already contains the disk number)
    mov     ch, 0x0
    mov     cl, 0x2
    mov     dh, 0x0

    ; actual read and exit
    int     0x13
    ret



; stall when an error occurs
halt:
    hlt
    jmp     halt



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
