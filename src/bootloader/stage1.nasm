; the stage1 code is contained in the Master Boot Record (MBR)
%include "src/bootloader/linking.nasm"


ORG 0x7c00
BITS 16



; force the cs:ip
jmp     0x0000:entry

entry:
    ; setup the stack
    mov     sp, STACK_BASE

    ; store drive number
    mov     [BOOT_DISK], dl

    ; test lba availability on the bios
    call    test_lba

    ; look for a bootable partition
    call    find_bootable

    ; test filesystem on the bootable partition
    call    test_filesystem

    ; retrieve the Logical Block Addressing (LBA) of the bootable partition
    ; the retrieve_lba routine also checks the size of partition and its
    ; offset, in order to trigger an error if it is superior to 2^16 sectors.
    call    retrieve_lba

    ; set %es in unreal mode (limit 4GB)
    call    unreal_mode

    ; load the stage2 in memory at offset 0x7e00
    call    load_stage2

    ; jump into the stage2
    jmp     STAGE2_ADDR



test_lba:
    ; setup arguments
    mov     ah, 0x41
    mov     dl, byte [BOOT_DISK]
    mov     bx, 0x55aa

    ; execute test and leave
    int     0x13
    cmp     bx, 0xaa55
    jne     trigger_error
    ret



find_bootable:
    ; look for the bootable partition
    mov     bx, P_TABLE_BEG - 0x10

    bootable_loop:
    add     bx, 0x10

    ; test if bootable
    cmp     byte [bx], BOOTABLE
    je      bootable_found

    ; leave if at the end and trigger error, continue scanning otherwise
    cmp     bx, P_TABLE_END
    jne     trigger_error
    jmp     bootable_loop

    bootable_found:
    mov     [BOOT_PART_ADDR], word bx
    ret



test_filesystem:
    ; retrieve address of the bootable partition entry
    ; and test its "system id" field for the old minix filesystem value
    mov     bx, word [BOOT_PART_ADDR]
    mov     al, MINIX_CODE
    cmp     al, byte [bx + 4]
    jne     trigger_error
    ret



retrieve_lba:
    ; only retrieve the lower 16 bits of the LBA, considering the disk does not
    ; exceed 32MBytes, meaning all of its sector addresses are under 2^16
    ; easily done considering the architecture is likely little-endian
    mov     bx, word [BOOT_PART_ADDR]
    mov     cx, word [bx + 8]
    mov     [BOOT_LBA], cx

    ; if the LBA offset exceeds 2^16 bits, trigger an error
    mov     ax, word [bx + 10]
    cmp     ax, 0x0
    jne     trigger_error

    ; if LBA offset + partition size exceeds 2 ^ 16 bits, trigger an error
    ; if the size of the partition exceeds 2 ^ 16 bits, we already know.
    mov     ax, word [bx + 14]
    cmp     ax, 0x0
    jne     trigger_error

    add     cx, word [bx + 12]
    jc      trigger_error
    ret



unreal_mode:
    ; save flags, disable interrupts, load gdt infos, save %es base address
    pushfd
    push    es
    cli
    lgdt    [unreal_gdt_info]

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



load_stage2:
    ; setup arguments
    mov     ah, 0x42
    mov     dl, byte [BOOT_DISK]
    mov     si, ebr_addr

    ; read and leave if no error
    int     0x13
    cmp     ah, 0x0
    jne     trigger_error
    ret



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



unreal_gdt_info:
    dw      unreal_gdt_end - unreal_gdt - 1
    dd      unreal_gdt



unreal_gdt:
    ; null segment
    dd      0, 0

    ; kernel cs with 4GB limit, base address 0x0
    db      0xff, 0xff, 0x00, 0x00, 0x00, 10010010b, 11001111b, 0x00
unreal_gdt_end:



ebr_addr:
    db  0x10, 0x00
    dw  STAGE2_SIZE
    dw  STAGE2_ADDR, 0x0000
    dq  0x1



error_msg:
    db      "an error occurred", 0xa, 0xd, 0x0
