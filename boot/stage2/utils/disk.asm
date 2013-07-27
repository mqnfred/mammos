global disk_read
global disk_write



disk_read:
    mov     ecx, [esp + 8]
    mov     eax, [esp + 4]
    mov     edi, [esp + 12]

    next_sect:
    push    eax
    call    disk_master_routine
    pop     eax
    add     eax, 1

    sub     ecx, 1
    cmp     ecx, 0
    jne     next_sect

    ret



; pass as parameters:
;   eax:    LBA value on 28 bits
;   cl:     number of sectors to read
;   edi:    address of buffer to read in if ebx == 0x20
;   esi:    address of buffer from which to write from if ebx == 0x30
disk_master_routine:
    ; save 28 bits LBA in ebx
    and     eax, 0x0FFFFFFF
    mov     ebx, eax

    ; sent LBA mode and 3 highest bits of LBA address (27-24)
    mov     dx, 0x01F6
    shr     eax, 24
    and     eax, 0x3
    or      al, 11100000b
    out     dx, al

    ; send a NULL byte
    mov     dx, 0x1F1
    mov     al, 0
    out     dx, al

    ; send sector count
    mov     dx, 0x1F2
    mov     al, 1 ; %cl when working properly
    out     dx, al

    ; send lower 8 bits of LBA (7-0)
    mov     dx, 0x1F3
    mov     eax, ebx
    out     dx, al

    ; send next 8 bits of LBA (15-8)
    mov     dx, 0x1F4
    shr     eax, 8
    out     dx, al

    ; send next 8 bits of LBA (23-16)
    mov     dx, 0x1F5
    shr     eax, 16
    out     dx, al

    ; send READ SECTORS command
    mov     dx, 0x1F7
    mov     al, 0x20
    out     dx, al

    wait_irq_poll:
    ; wait for IRQ or poll
    in      al, dx
    test    al, 8
    jz      wait_irq_poll

    ; setup 256 words goal
    mov     eax, 256
    ; TODO: do things right without larger loop
    ; execute mul cx when working properly

    push    ecx ; preserve ecx for larger loop
    mov     ecx, eax
    mov     dx, 0x1F0

    ; read 256 * %cx words and continue if there are sectors left
    rep     insw
    pop     ecx ; preserve ecx for larger loop

    ret
