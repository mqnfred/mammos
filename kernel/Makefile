BIN		= ../bin
LDFLAGS	= -melf_i386 --gc-sections
CFLAGS	= -g -ggdb3 -m32 -Werror -Wall -Wextra -nostdlib -nostartfiles -nodefaultlibs -nostdinc -ffreestanding -std=c99


all: build_init build_drivers build_lib build_main link


build_init: init
	make -C init


build_drivers: drivers
	make -C drivers


build_lib: lib
	make -C lib


build_main: main
	make -C main


link:
	ld $(LDFLAGS) -T kernel.ld objs/*.o -o $(BIN)/kernel.bin --oformat=binary
	ld $(LDFLAGS) -T kernel.ld objs/*.o -o $(BIN)/kernel.o


clean:
	rm -rf objs
