include ../../Makefile.inc


CFLAGS 		+= -I../ -I../../include


all: stage2.ld
	$(CC) $(CFLAGS) -c stage2.c -o stage2.o
	$(CC) $(CFLAGS) -c fs/minix.c -o fs/minix.o
	$(CC) $(CFLAGS) -c fs/fat.c -o fs/fat.o
	$(CC) $(CFLAGS) -c utils/tools.c -o utils/tools.o

	$(AS) $(ASFLAGS) utils/disk.asm -o utils/disk.o
	
	$(LD) $(LDFLAGS) -T stage2.ld
	objcopy -O binary stage2.elf stage2.bin
	chmod a-x stage2.bin


clean:
	rm -f fs/*.o utils/*.o *.o stage2.elf stage2.bin
