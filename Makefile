.PHONY: kernel check


all: bootloader kernel


kernel:
	make -C kernel


bootloader:
	make -C boot


floppy: all
	make floppy -C check


clean:
	make clean -C boot
	make clean -C kernel
	make clean -C check


distclean: clean
	rm -rf bin
	make distclean -C check


check: floppy
	make check -C check


test: floppy
	make test -C check
