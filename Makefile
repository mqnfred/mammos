include Makefile.am


all: bootloader


bootloader: bin stage1 stage2


stage1:
	# generate flat binary linked at offset 0x7c00 and then
	# blend in the stage1 at offset 0x0 (MBR) in the disk
	nasm $(STAGE1_SRC) -o $(STAGE1_BIN)
	dd if=$(STAGE1_BIN) of=$(DEVICE) bs=1 count=$(STAGE1_SIZE) conv=notrunc


stage2:
	# generate flat binary linked at offset 0x7e00 and then
	# blend it in the drive at offset 512 bytes (right after MBR) in the disk
	nasm $(STAGE2_SRC) -o $(STAGE2_BIN)
	dd if=$(STAGE2_BIN) of=$(DEVICE) bs=1 count=$(STAGE2_SIZE) seek=512 conv=notrunc


check: all
	qemu-system-i386 $(DEVICE) -s -S


bin:
	mkdir bin


clean:
	rm -rf bin
