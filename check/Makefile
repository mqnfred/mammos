BIN		= ../bin


check: floppy
	qemu-system-i386 -m 4096 drive


test: floppy
	./launchqemu.sh
	sleep 0.5
	gdb -x gdb.init


dev:
	su -c "while true; do make test; done"


drive:
	dd if=/dev/zero of=drive bs=1M count=64
	mkfs.minix -1 drive


floppy: drive blend_bootloader
	cp $(BIN)/kernel.bin filesystem/boot/kernel
	
	sudo mount drive mnt
	sudo cp -r filesystem/* mnt
	sudo umount mnt


blend_bootloader:
	dd if=$(BIN)/boot.bin of=drive bs=1 count=1024 conv=notrunc


clean:
	rm -rf filesystem/boot/kernel
	rm -f qemu.pid


distclean:
	rm -f drive
