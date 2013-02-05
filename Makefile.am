# basic drive variables
DEVICE			= utils/drive
PART_TABLE		= utils/partitions


# bootloader variables
STAGE1_SRC		= src/bootloader/stage1.nasm
STAGE2_SRC		= src/bootloader/stage2.nasm
STAGE1_BIN		= bin/stage1.bin
STAGE2_BIN		= bin/stage2.bin
STAGE1_SIZE		= `wc -c $(STAGE1_BIN) | cut -d ' ' -f 1`
STAGE2_SIZE		= `wc -c $(STAGE2_BIN) | cut -d ' ' -f 1`


# kernel variables
KERNEL_SRC		= src/kernel/kernel.nasm
KERNEL_BIN		= bin/kernel.bin
KERNEL_SIZE 	= `wc -c $(KERNEL_BIN) | cut -d ' ' -f 1`
