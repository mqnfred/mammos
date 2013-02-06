; stage2, stored in the EBR, loaded by stage1
; for more information, see the /design.md file


%define STAGE2_ENTRY    0x7e00


ORG STAGE2_ENTRY
BITS 16



stage2_entry:
    call    read_superblock

    hlt
    jmp     stage2_entry


read_superblock:
    ; pop the return address to retrieve the arguments
    pop     bp

    ; set opcode, copy address and amount to read
    ; the superblock is 1024 bytes, 2 sectors
    mov     ah, 0x2
    mov     bx, 0x500
    mov     al, 10

    ; retrieve respectively the head, sector and cylinder of partition1
    pop     si
    pop     dx
    mov     dh, [si + 1]
    mov     cl, [si + 2]
    mov     ch, [si + 3]

    ; the first block of a minix fs is a boot block, we want the next, this
    ; means 2 sectors over
    add     cl, 2

    ; read, restore return address and leave the routine
    int     0x13
    push    bp
    ret
