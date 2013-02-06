; stage2, stored in the EBR, loaded by stage1
; for more information, see the /design.md file


%define STAGE2_ENTRY    0x7e00
%define KERNEL_OFFSET   0x100000


ORG STAGE2_ENTRY
BITS 16



stage2_entry:
    ; pop the drive number and the bootable partition lba (2 words)
    pop     di
    pop     si
    pop     dx

    call    load_kernel


load_kernel:
    ; load the super-block of the bootable partition
    ; also skip the first boot block (2 sectors)
    mov     bx, 0x500
    mov     cx, 2 ; 2 sectors = 1 block
    mov     ax, 2
    call    arith_32bit
    call    read_sectors

    ; get block size in bytes
    mov     bx, 1024
    shl     bx, word [0x500 + 10]

    ; get the offset of the inode table in bytes
    mov     ax, word [0x500 + 4]
    add     ax, word [0x500 + 6]
    mul     bx

    ; we do not handle a huge amount
    cmp     dx, 0x0
    jne     stall

    ; add superblock bootblock 2 * 1024 sizes
    add     ax, 2048
    mov     [es:0x10000], ax


    ret



; use:  sector offset (low 16 bits) in %si
;       sector offset (high 16 bits) in %di
;       memory destination in $bx (segment assumed to be 0)
;       number of sectors to read in %cx
read_sectors:
    ; push the DAP in inverse order (little-endian, stack grows down)
    ; only access 32 bits of the 64 bits of the LBA offset
    push    0x0000
    push    0x0000
    push    di
    push    si
    push    0x0000
    push    bx
    push    cx
    push    0x0010

    ; read with the DAP at %es and leave if no error, stall otherwise
    mov     si, sp
    mov     ah, 0x42
    int     0x13
    cmp     ah, 0x0
    jne     stall

    ; pop out the DAP
    mov     ax, 0x0
    popout:
    pop     bx
    add     ax, 0x1
    cmp     ax, 0x8
    jne     popout
    ret



; TODO: not working atm, overflow flag is not set???!
; use:  add the content of %ax to the sum of (%di << 16 + %si)
arith_32bit:
    add     si, ax
    jo      overflow
    ret

    overflow:
    add     di, 1
    ret



stall:
    hlt
    jmp     stall
