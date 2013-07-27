; by Louis Feuvrier on 9/7/13
; this mbr (stage 1) loads a stage 2, gets to protected mode and jump

extern chunk_offset
extern stage2
global stage1



section .text
BITS 16
; make sure the %cs and %eip are correctly initialized
; trash nothing
stage1:
    jmp     0x0:start



; main function
start:
    mov     sp, stage1
    mov     byte [disk_nbr], dl
    call    test_lba
    call    unreal_mode
    call    load_stage2
    jmp     jump_stage2



; call the BIOS function in order to detect wether or not LBA addressing
; is available in this context. trashes nothing
test_lba:
    pushad

    ; setup arguments
    mov     ah, 0x41
    mov     dl, byte [disk_nbr]
    mov     bx, 0x55aa

    ; execute test and leave
    int     0x13
    cmp     bx, 0xaa55
    jne     error

    popad
    ret



; switch to unreal mode function (trash nothing)
unreal_mode:
    pushad
    pushfd

    ; disable interrupts, load gdt infos, save %es base address
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
    popad
    ret



; load the stage 2 at offset 0x7E00
load_stage2:
    pushad

    ; we start by loading only 63 sectors from the dead space
    ; lba of dead space is 1 (0 is this mbr)
    mov     ax, 64
    mov     bx, 1

    mov     edi, stage2
    mov     dl, [disk_nbr]

    call    read_sectors

    ; %ax, %bx, %dl and %edi are not trashed since we pushed them before
    ; invoking the read_sectors function
    popad
    ret



; read %ax sectors from LBA offset %bx of disk %dl to memory at %edi
; trashes %ax, %bx, %dl, %edi
read_sectors:
    pushad

    ; prepare Disk Address Packet (DAP)
    mov     byte [dap], 0x10
    mov     byte [dap + 1], 0x00
    mov     word [dap + 2], 0x0001
    mov     dword [dap + 4], chunk_offset
    mov     dword [dap + 12], 0x00000000
    mov     word [dap + 10], 0x0000

    add     ax, bx

    copy_loop:
    ; retrieve the chunk from the disk
    push    ax
    mov     ah, 0x42
    mov     si, dap
    mov     word [dap + 8], bx
    int     0x13
    pop     ax

    ; copy that chunk at index %edi
    mov     cx, 0x200
    mov     esi, chunk_offset
    a32     rep movsb

    inc     bx
    cmp     bx, ax
    jne     copy_loop

    popad
    ret



; print the message at address %si and hang the CPU
error:
    ; setup args
    mov     si, error_msg
    xor     ax, ax
    mov     ds, ax
    cld

    ; print string
    print_loop:
    lodsb
    mov     bx, 0x1
    mov     ah, 0xE
    int     0x10

    ; load [si] into al and test if end of string
    cmp     al, 0x0
    jnz     print_loop
    jmp     halt



; simple hang function
halt:
    hlt
    jmp     halt



jump_stage2:
    ; disable interrupts and load gdt
    cli
    lgdt    [gdt_info]

    ; actual switch to protected mode and leave the routine
    mov     eax, cr0
    or      al, 1
    mov     cr0, eax

    ; push the address of the partition table
    push    dword 0x7C00 + 0x1BE

    ; set the CS register
    jmp     0x8:pmode

    BITS 32
    pmode:
    call    stage2;
    jmp     halt



section .data

error_msg:
    db      "an error occured", 0xA, 0xD, 0x0

; space receiving the master disk ID (usually 0x80)
disk_nbr:
    db      0x0

; gdt table with 1 NULL segment and %cs %ds kernel land flat segments
; used for both the unreal mode and the temporary protected mode
gdt_info:
    dw      gdt_end - gdt - 1
    dd      gdt
gdt:
    dd      0x0, 0x0
    db      0xff, 0xff, 0x00, 0x00, 0x00, 10011010b, 11001111b, 0x00
    db      0xff, 0xff, 0x00, 0x00, 0x00, 10010010b, 11001111b, 0x00
    dd      0x0, 0x0
gdt_end:

; reserve space for the DAP used in the read_sectors function
dap:
    db      0x0, 0x0
    dw      0x0
    dd      0x0, 0x0
