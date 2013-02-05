; the stage2 is loaded by the stage1 at offset 0x7e00

; the incoming stack is the following:
;
; +-----------------------------+ STACK_BASE (likely 0x7bf0)
; | old dx (drive number in dl) |
; +-----------------------------+ 0x7bee
; | partition entry address     |
; +-----------------------------+ 0x7bec

%define STAGE1_ENTRY 0x7c00
%define STAGE2_ENTRY 0x7e00

%define KERNEL_OFFSET 0x100000
%define CHUNK_SIZE 0x1 ; in sectors
%define CHUNK_OFFSET 0x500 ; free of use chunk below the stack, abose BDA

ORG STAGE2_ENTRY
BITS 16


stage2_entry:
    ; load the kernel into memory
    call    load_kernel
    call    print_msg
    call    halt


; print the following message in order to indicate to the user that everything
; is doing fine.
msg:
    db      "Stage 2 loading!", 0xd, 0xa, 0x0
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


halt:
    hlt
    jmp     halt


load_kernel:
    ; set opcode, address (es:bx) and number of sectors to copy
    mov     ah, 0x2
    mov     al, CHUNK_SIZE
    mov     bx, CHUNK_OFFSET

    ; pop in si the address of the bootable partition entry (see above).
    ; to avoid poping the return address, save it in cx
    pop     cx
    pop     si
    pop     dx
    push    cx

    ; retrieve head, sector and cylinder informations from partition entry
    mov     dh, [si + 1]
    mov     cl, [si + 2]
    mov     ch, [si + 3]

    ; this is the offset of the kernel, %di will increase at each move_chunk
    a32 mov edi, KERNEL_OFFSET

load_kernel_loop:
    ; retrieve chunk and move it
    int     0x13
    call    move_chunk

    ; increase sector index and check that it's not out of cylinder boundaries
    add     cl, 0x1
    cmp     cl, 63
    jne     load_kernel_loop

    ; when all cylinder's sectors are read, we move on to the next cylinder
    mov     cl, 0x1
    add     ch, 0x1
    cmp     ch, 0x2 ; at the moment we only read 63 sectors, TODO read 16MB
    jne     load_kernel_loop

    ret


move_chunk:
    ; save cx, it contains both the cylinder and the sector number
    push    cx

    ; copy the data, %di is already set and should not be moved to append
    mov     cx, CHUNK_SIZE * 0x200
    a32 mov esi, CHUNK_OFFSET
    a32 rep movsb

    ; restore cx
    pop     cx
    ret


jump_kernel:
    cli
    lgdt    [gdt_info]

    ; set other registers
    mov     eax, 0x10
    mov     ds, eax
    mov     eax, 0x18
    mov     ss, eax

    ; set PE bit
    mov     eax,cr0
    or      al, 0x1
    mov     cr0, eax


BITS 32
    ; we're out of here!
    jmp     0x8:KERNEL_OFFSET
    nop
    nop

gdt_info:
    dw      gdt_end - gdt - 1
    dd      gdt

; the following is the global descriptor table used by the kernel in protected
; mode. the bytes are displayed in little-endian
gdt:
    ; null segment
    dq      0x0

    ; kernel cs
    db      0x0, 0xdf, 0x9a, 0x0, 0x0, 0x0, 0xff, 0xff

    ; kernel ds
    db      0x0, 0xdf, 0x92, 0x0, 0x0, 0x0, 0xff, 0xff

    ; kernel ss
    db      0x0, 0xdf, 0x92, 0x0, 0x0, 0x0, 0xff, 0xff

    ; user cs
    db      0x0, 0xdf, 0xfa, 0x0, 0x0, 0x0, 0xff, 0xff

    ; user ds
    db      0x0, 0xdf, 0xf2, 0x0, 0x0, 0x0, 0xff, 0xff

    ; tss, dummy atm TODO
    dq      0x0
gdt_end:
