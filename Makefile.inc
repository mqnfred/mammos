CC			:= gcc

CFLAGS		:= -m32 -ggdb3 -g -std=c99
CFLAGS		+= -Werror -Wall -Wno-unused-variable -Wno-unused-parameter
CFLAGS		+= -ffreestanding -fno-builtin -nostdlib -nodefaultlibs

AS			:= nasm
ASFLAGS		:= -f elf -g

LD			:= ld
LDFLAGS		:= -melf_i386

DRIVE		:= check/drive
PARTITIONS	:= check/partitions
STAGE1		:= boot/bin/stage1.bin
STAGE2		:= boot/bin/stage2.bin

GDBINIT		:= check/gdbinit
