extern data_offset
extern kernel_offset
extern trigger_error
extern read_sectors
global stage2

section .text
BITS 16



stage2:
    ; load superblock and check various MINIX flags
    call    load_superblock
    call    check_minix

    ; retrieve inode offset of boot directory in [data_offset + 28]
    ; assumes that it is the first data zone, which it is. If the boot
    ; directory is not one of the first 32 entries, then exit with error atm
    call    load_rootdir
    mov     ax, 0xa000
    mov     bx, boot_name
    call    search_dir
    mov     ax, [si]
    mov     [data_offset + 28], ax

    ; load inode map at ofset 0xc000
    call    load_inode_table

    ; load boot directory at offset 0xe000
    ; first get offset of inode entry in memory
    mov     si, [data_offset + 28]
    sub     si, 1
    shl     si, 5
    add     si, 0xc000

    ; load the zone offset of the boot directory in bx (in sectors)
    ; and load the boot directory in memory at offset 0xe000
    add     si, 14
    mov     bx, [si]
    shl     bx, 1
    call    load_bootdir

    ; search the boot directory at offset 0xe000 for the file named 'kernel'
    ; and store its inode offset in [data_offset + 30]
    mov     ax, 0xe000
    mov     bx, kernel_name
    call    search_dir
    mov     ax, [si]
    mov     [data_offset + 30], ax

    ; get offset of kernel inode entry in memory
    mov     si, [data_offset + 30]
    sub     si, 1
    shl     si, 5
    add     si, 0xc000

    ; finally load the kernel in memory
    call    load_kernel_zones



load_superblock:
    mov     dl, byte [data_offset]
    mov     edi, 0x8000
    mov     bx, 2
    mov     ax, 2
    call    read_sectors
    ret



check_minix:
    ; check that this is MINIX V1 filesystem with 30 char long names
    mov     ax, [0x8000 + 0x10]
    cmp     ax, 0x138f
    jne     trigger_error

    ; check that the zone size is 1kb (1 block)
    ; which means that the log_zone_size is 0
    mov     ax, [0x8000 + 0xa]
    cmp     ax, 0
    jne     trigger_error
    ret



load_rootdir:
    mov     edi, 0xa000
    mov     dl, [data_offset]
    mov     ax, 2
    mov     bx, [0x8000 + 8]
    shl     bx, 1

    call    read_sectors
    ret



search_dir:
    add     ax, 2

    push    bx
    mov     bx, ax
    add     bx, 2 * 512

    test_loop:
    mov     cx, 5
    mov     di, ax
    mov     si, word [esp]

    repe    cmpsb
    je      dir_found

    add     ax, 32
    cmp     ax, bx
    jne     test_loop
    jmp     trigger_error

    dir_found:
    sub     ax, 2
    mov     si, ax
    add     esp, 2
    ret



load_inode_table:
    ; get inode map address in sectors
    mov     bx, 2
    add     bx, word [0x8000 + 4]
    add     bx, word [0x8000 + 6]
    shl     bx, 1

    ; fill out the rest of the arguments
    mov     dl, byte [data_offset]
    mov     edi, 0xc000
    mov     ax, 2
    call    read_sectors
    ret



load_bootdir:
    mov     edi, 0xe000
    mov     dl, [data_offset]
    mov     ax, 2

    call    read_sectors
    ret



load_kernel_zones:
    ; get zone address start in inode entry
    add     si, 14

    ; get zone address max in inode entry
    mov     cx, si
    add     cx, 18

    ; constant values loading
    mov     dl, byte [data_offset]
    mov     edi, kernel_offset

    loading_loop:
    ; loading one block (aka 2 sectors)
    mov     ax, 2

    ; get zone offset in sectors instead of blocks
    mov     bx, [si]
    shl     bx, 1

    ; call the read_sectors routine while preserving registers
    pushad
    call    read_sectors
    popad

    ; continue if there are still blocks to load
    add     si, 2
    cmp     si, cx
    je      done
    cmp     word [si], 0
    je      done

    ; adjust offset in memory for next iteration
    add     edi, 2 * 512
    jmp     loading_loop

    done:
    ret


section .data
boot_name:
    db      "boot", 0x0
kernel_name:
    db      "kernel", 0x0
