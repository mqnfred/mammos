# Bootloader design


stage1:
    go into unrealmode
    setup stack
    get lba of bootable partition
    load stage2
    jump off dat cliff


stage2:
    load the kernel
        open the file system and detect position of kernel
        load kernel 512 bytes chunks at a time at offset blow 64kB
        move chunks at offset 0x100000
    setup (temporary) gdt/idt
    switch to protected mode
    turn on pagination
    jump into the kernel

memory:


...
ebda
free space
stage-independent data
stage 2 code
stage 1 code
bootloader stack
stage-dependent data
bda
ivt
