# the device on which to install the bootloader/os
DEVICE			= check/drive

# variables about the stage1 building
STAGE1_SRC		= src/bootloader/stage1.nasm
STAGE1_BIN		= bin/stage1.bin
STAGE1_SIZE		= `wc -c $(STAGE1_BIN) | cut -d ' ' -f 1`

# variables about the stage2 building
STAGE2_SRC		= src/bootloader/stage2.nasm
STAGE2_BIN		= bin/stage2.bin
STAGE2_SIZE		= `wc -c $(STAGE2_BIN) | cut -d ' ' -f 1`
