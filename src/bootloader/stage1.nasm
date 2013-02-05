; the stage1 (MBR) is loaded at offset 0x7c00

%define STAGE1_ENTRY 0x7c00
%define STAGE2_ENTRY 0x7e00
%define STAGE2_SIZE 0x3e ; in sectors (0x3e * 512 bytes)
%define STACK_BASE 0x7bf0 ; under the mbr in memory at 0x7c00

ORG STAGE1_ENTRY
BITS 16


stage1_entry:
    ; indicate that we're in stage1
    call    print_msg

    ; only the %es segment register will be switched to unreal mode
    call    enter_unrealmode

    ; set a tidy stack just below the mbr, and before the IVT/BDA
    mov     sp, STACK_BASE

    ; find bootable partition for our master, stage2
    ; it's most likely the first one
    ; also save the disk number, which is in dl
    push    dx
    call    find_bootable

    ; we're out of here
    call    load_stage2
    jmp     STAGE2_ENTRY


; print the following message in order to indicate to the user that everything
; is doing fine.
msg:
    db      "Stage 1 loading!", 0xd, 0xa, 0x0
print_msg:
    mov     si, msg
    mov     bh, 0x1
    mov     ah, 0xe

    ; iterate over the characters and print them
print_msg_loop:
    ; print character
    mov     al, [si]
    int     0x10

    ; go on to the next character, leave if it is 0
    add     si, 0x1
    cmp byte [si], 0x0
    jne     print_msg_loop

    ret


load_stage2:
    ; set opcode, copy address and number of sectors to copy
    mov     ah, 0x2
    mov     al, STAGE2_SIZE
    mov     bx, STAGE2_ENTRY

    ; set respectively head, sector and cylinder
    mov     dh, 0x0
    mov     cl, 0x2
    mov     ch, 0x0

    ; let's roll
    int     0x13
    ret


; we set only es in unrealmode, since ds or ss can create problems with
; BIOS routine calls this will stil allow us to access the whole 4GB memory
; with es:addr
unreal_gdt_info:
    dw      enter_unrealmode - unreal_gdt - 1 ; enter_unrealmode = end of gdt
    dd      unreal_gdt
unreal_gdt:
    dd      0, 0 ; null segment
    db      0xff, 0xff, 0, 0, 0, 10010010b, 11001111b, 0
enter_unrealmode: ; mark both the start of the function and the end of the gdt
    ; save flags, block interrupts and load the gdt in gdtr
    pushfd
    cli
    lgdt    [unreal_gdt_info]

    ; save base of register
    push    es

    ; enter pmode
    mov     eax,cr0
    or      al,1
    mov     cr0,eax

    ; load gdt entry with 4GB limit
    mov     bx, 0x8
    mov     es, bx

    ; exit pmode
    mov     eax, cr0
    and     al, 0xfe
    mov     cr0, eax

    ; retrieve base of register
    pop     es

    ; restore flags and leave
    popfd
    ret


; push into the stack the bootable partition entry
; if no bootable partition is found, pick the first one
find_bootable:
    ; save the return address to push it before returning
    pop     ax
    mov     bx, STAGE1_ENTRY + 0x1be - 0x10

find_bootable_loop:
    add     bx, 0x10

    ; 0x80 is the valid value for a bootable partition
    cmp byte [bx], 0x80
    je      find_bootable_endwell

    ; there's only 4 primary partitions valid
    cmp     bx, STAGE1_ENTRY + 0x1ee
    jne     find_bootable_loop

    ; no bootable partition was found, default it to the first one
    mov     bx, STAGE1_ENTRY + 0x1be

; push the address of the bootable partition entry and move
find_bootable_endwell:
    push    bx

    ; don't forget to push the return address before returning
    push    ax
    ret
