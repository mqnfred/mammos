    ; disk driver read/write routines


global disk_read
global disk_write



disk_read:
    mov     eax, [esp + 4]
    mov     ecx, [esp + 8]
    mov     edi, [esp + 12]

    mov     ebx, 0x20
    call    disk_master_routine
    ret



disk_write:
    mov     eax, [esp + 4]
    mov     ecx, [esp + 8]
    mov     esi, [esp + 12]

    mov     ebx, 0x30
    call    disk_master_routine
    ret



; pass as parameters:
;   eax:    LBA value on 28 bits
;   ebx:    command (0x20 read or 0x30 write)
;   cl:     number of sectors to read
;   edi:    address of buffer to read in if ebx == 0x20
;   esi:    address of buffer from which to write from if ebx == 0x30
disk_master_routine:
    pushad
    push    ebx

    ; LBA value is on 28 bits
    and     eax, 0x0FFFFFFF
    mov     ebx, eax

    ; send bits 24-27 of LBA
    mov     edx, 0x01F6
    shr     eax, 24
    or      al, 11100000b
    out     dx, al

    ; send number of sectors (contained in %cl)
    mov     edx, 0x01F2
    mov     al, cl
    out     dx, al

    ; send bits 0-7 of LBA
    mov     edx, 0x01F3
    mov     eax, ebx
    out     dx, al

    ; send bits 8-15 of LBA
    mov     edx, 0x01F4
    mov     eax, ebx
    shr     eax, 8
    out     dx, al

    ; send bits 16-23 of LBA
    mov     edx, 0x01F5
    mov     eax, ebx
    shr     eax, 16
    out     dx, al

    ; send command port (read with retry)
    ; get the command (0x20 read or 0x30 write)
    mov     edx, 0x01F7
    mov     eax, [esp]
    out     dx, al

    still_going:
    ; require servicing until serviced
    in      al, dx
    test    al, 8
    jz      still_going

    ; reading/writing 256 words (a 512 bytes sector)
    mov     eax, 256

    ; reading/writing 256 * %cl words into %edi
    xor     bx, cx
    mov     bl, cl
    mul     bx
    mov     ecx, eax
    mov     edx, 0x01F0

    cmp     dword [esp], 0x20
    je      read

    write:
    rep     outsw
    jmp     done

    read:
    rep     insw
    jmp     done

    done:
    add     esp, 4
    popad
    ret
