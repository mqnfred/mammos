include ../../Makefile.inc


CFLAGS 		+= -I./ -I../../include


all: stage1.asm stage1.ld
	$(AS) $(ASFLAGS) -o stage1.o stage1.asm
	$(LD) $(LDFLAGS) -T stage1.ld
	objcopy -O binary stage1.elf stage1.bin
	chmod a-x stage1.bin


clean:
	rm -f stage1.o stage1.elf stage1.bin
