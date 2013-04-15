extern stack_offset
extern chunk_offset
extern data_offset
extern stage2
global gdt_info
global read_sectors
global trigger_error
global start

section .text
BITS 16



start:
    jmp     0x0:stage1



stage1:
    ; setup
    mov     sp, stack_offset
    mov     [data_offset], dl
    call    test_lba
    call    unreal_mode

    ; load stage2 and jump
    call    load_stage2
    jmp     0x0:stage2



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
    mov     dl, byte [data_offset]
    mov     bx, 0x55aa

    ; execute test and leave
    int     0x13
    cmp     bx, 0xaa55
    jne     trigger_error
    ret



load_stage2:
    mov     dl, byte [data_offset]
    mov     edi, stage2
    mov     bx, 1
    mov     ax, 1
    call    read_sectors
    ret



read_sectors:
    ; assumes a sector size of 512 bytes
    ; arguments are:
    ;   - %edi: destination (unreal mode enabled %es with 4GB limit)
    ;   - %dl: disk to read from
    ;   - %bx: LBA offset to read
    ;   - %ax: number of sectors to read

    ; prepare Disk Address Packet (DAP)
    mov     byte [data_offset + 2], 0x10
    mov     byte [data_offset + 3], 0x00
    mov     word [data_offset + 4], 0x0001
    mov     dword [data_offset + 6], chunk_offset
    mov     dword [data_offset + 14], 0x00000000
    mov     word [data_offset + 12], 0x0000

    add     ax, bx

    copy_loop:
    ; retrieve the chunk from the disk
    push    ax
    mov     ah, 0x42
    mov     si, data_offset + 2
    mov     word [data_offset + 10], bx
    int     0x13
    pop     ax

    ; copy that chunk at index %edi
    mov     cx, 0x200
    mov     esi, chunk_offset
    a32     rep movsb

    inc     bx
    cmp     bx, ax
    jne     copy_loop
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



section .data
error_msg:
    db      "an error occurred", 0xa, 0xd, 0x0
gdt_info:
    dw      gdt_end - gdt - 1
    dd      gdt
gdt:
    dd      0x0, 0x0
    db      0xff, 0xff, 0x00, 0x00, 0x00, 10011010b, 11001111b, 0x00
    db      0xff, 0xff, 0x00, 0x00, 0x00, 10010010b, 11001111b, 0x00
    dd      0x0, 0x0
gdt_end:
