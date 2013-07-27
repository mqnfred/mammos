include Makefile.inc


all: stage1 stage2


stage1: boot/
	make stage1 -C boot/


stage2: boot/
	make stage2 -C boot/


drive: all
	DRIVE=$(DRIVE) PARTITIONS=$(PARTITIONS) STAGE1=$(STAGE1) STAGE2=$(STAGE2) check/mkdrive.sh


partitions:
	DRIVE=$(DRIVE) PARTITIONS=$(PARTITIONS) STAGE1=$(STAGE1) STAGE2=$(STAGE2) check/mkdrive.sh partition


check: qemu
qemu: drive
	DRIVE=$(DRIVE) GDBINIT=$(GDBINIT) check/emulate.sh qemu


bochs: drive
	DRIVE=$(DRIVE) GDBINIT=$(GDBINIT) check/emulate.sh bochs


clean:
	make clean -C boot


distclean: clean
	rm -f $(DRIVE)
	make distclean -C boot
