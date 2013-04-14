BIN		= ../bin


check: floppy
	qemu-system-i386 -m 4096 drive


test: floppy
	qemu-system-i386 -m 4096 drive -s -S 2>&1 1>/dev/null &
	sleep 0.5
	gdb -x gdb.init -f $(BIN)/boot.o $(BIN)/kernel.o


drive:
	dd if=/dev/zero of=drive bs=1M count=64
	mkfs.minix -1 drive


floppy: drive
	dd if=$(BIN)/boot.bin of=drive bs=1 count=1024 conv=notrunc
	
	cp $(BIN)/kernel.bin filesystem/boot/kernel
	
	sudo mount -t minix drive mnt
	sudo cp -r filesystem/* mnt
	sudo umount mnt


clean:
	rm -rf filesystem/boot/kernel


distclean:
	rm -f drive
