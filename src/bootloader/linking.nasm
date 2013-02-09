%ifndef LINKING_
    %define LINKING_

    ; size of a sector in bytes
    %define SECTOR_SIZE     0x200

    ; loaded there by the BIOS
    %define STAGE1_ADDR     0x7c00

    ; address of the beginning and end of the partition table in memory
    %define P_TABLE_BEG     STAGE1_ADDR + 0x1be
    %define P_TABLE_END     STAGE1_ADDR + 0x1ee

    ; right after the end of stage1
    %define STAGE2_ADDR     0x7e00

    ; in 512 bytes sectors
    %define STAGE2_SIZE     0x3e

    ; after the first occupied MB in memory, 1024 bytes max
    ; since stored in the boot sector of the bootable partition atm.
    %define KERNEL_OFFSET   0x100000
    %define KERNEL_SIZE     0x400

    ; the offset of the data structure containing all the information about the
    ; disk containing the bootloader/os, etc. from 0x500 to 0x600 max.
    ; 0x500 is right above the Bios Data Area (BDA).
    ; the following defines match the fields in the data structure.
    %define DATA_OFFSET     0x500

    %define BOOT_DISK       DATA_OFFSET
    %define BOOT_PART_ADDR  DATA_OFFSET + 2
    %define BOOT_LBA        DATA_OFFSET + 4

    ; chunk size. kernel is copied one chunk at a time and then moved
    ; to the matching location at 0x100000. the chunk position is right above
    ; the data structure,about 30kB below the stack
    %define CHUNK_OFFSET    0x600
    %define CHUNK_SIZE      0x1

    ; the code of the MINIX filesystem in the partition table. this is the only
    ; one tolerated. BOOTABLE is the code marking a bootable partition.
    %define MINIX_CODE      0x80
    %define BOOTABLE        0x80

    ; right below the offset of stage1, 16 bytes aligned, grows down
    %define STACK_BASE      0x7bf0
%endif
