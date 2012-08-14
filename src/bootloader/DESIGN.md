# Bootloader design


stage1:
    setup stack
    store disk number
    go into unrealmode
    test lba routines
    get lba of bootable partition
    load stage2
    jump off dat cliff


stage2:
    load kernel (in boot sector of bootable partition atm)
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
