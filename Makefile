include Makefile.am


all: bin bootloader


# make and apply both stage1 and stage2 on the drive
bootloader: stage1 stage2


# apply the stage1 logic on the drive
stage1:
	# make the stage1 binary
	nasm $(STAGE1_SRC) -o $(STAGE1_BIN)
	
	# blend in the drive the first 440 bytes of the MBR
	dd bs=1 count=$(STAGE1_SIZE) conv=notrunc if=$(STAGE1_BIN) of=$(DEVICE)


# apply the stage2 logic on the drive
stage2:
	# make the stage2 binary
	nasm $(STAGE2_SRC) -o $(STAGE2_BIN)
	
	# blend in the drive the whole thing, starting at sector 2
	dd bs=1 count=$(STAGE2_SIZE) seek=512 conv=notrunc if=$(STAGE2_BIN) of=$(DEVICE)


# launch qemu and have it wait for a gdb client to connect
check: all
	qemu-system-i386 $(DEVICE) -s -S


# clean both the drive and the generated binaries
clean:
	rm -rf bin


bin:
	mkdir bin
