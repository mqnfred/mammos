# tarball structure
SRCDIR		= src/
OBJDIR		= objs/
BINDIR		= bin/
CHECKDIR	= check/

# binary names definition
BOOT_BIN	= $(BINDIR)boot.bin
KERN_BIN	= $(BINDIR)kernel.bin

# compiler, assembler and linker definition
CC			= gcc
AS			= nasm
LD			= ld
CPY			= objcopy

# compiler, assembler and linker flags
CFLAGS		= -m32 -Iinclude -Werror -Wall -Wextra -nostdlib -nostartfiles -nodefaultlibs -nostdinc -ffreestanding -std=c99
ASFLAGS		= -f elf
LDFLAGS		= -melf_i386 --gc-sections
CPYFLAGS	= --remove-section .eh_frame --remove-section .comment

# kernel source files
C_SRC		= kernel.c gdt.c idt.c stdlib.c memory.c
AS_SRC		= entry.asm isr.asm
LD_SRC		= linker.ld

# kernel object files
OBJS		= $(addprefix $(OBJDIR), $(addprefix asm_, $(AS_SRC:.asm=.o)) $(C_SRC:.c=.o))

# bootloader various definitions
BOOT_SRC	= boot.asm

# drive and table definition
DRIVE		= $(CHECKDIR)drive
TABLE		= $(CHECKDIR)table

# emulator and debugger definition
EM			= qemu-system-i386
DB			= gdb

# emulator flags
EMFLAGS		= -s -S
DBFLAGS		= -q

# various debugger definitions
# the elf kernel is used to match symbols with addresses whlie debugging
KERN_ELF	= $(BINDIR)kernel.elf
DB_SCRIPT	= $(CHECKDIR)gdb.init
