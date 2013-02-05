include Makefile.am


all: bin bootloader kernel


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


# the kernel is located at offset 0x7e00 in the disk, meaning the sector no. 1
# (base 0) of the second cylinder (1, base 0)
# this is because the kernel is at offset 0x0 in the first partition, which is
# at the first sector of the second cylinder.
# 0x7e00 == 32256
kernel:
	# make the kernel
	nasm $(KERNEL_SRC) -o $(KERNEL_BIN)
	
	# blend the kernel in the device
	dd bs=1 count=$(KERNEL_SIZE) seek=32256 conv=notrunc if=$(KERNEL_BIN) of=$(DEVICE)


# write a 1GB drive with following partitionning:
# - 16.46MB (kernel partition, not formated)
# - 131.61MB (root partition)
# - 925.69MB (home partition)
device:
	# create the drive
	dd bs=1M count=1024 if=/dev/zero of=$(DEVICE)
	
	# blend in the partitions and MBR magic number 
	dd bs=1 count=512 conv=notrunc if=$(PART_TABLE) of=$(DEVICE)


# launch qemu and have it wait for a gdb client to connect
check: all
	qemu-system-i386 $(DEVICE) -s -S


# clean both the drive and the generated binaries
clean:
	rm -rf bin
	rm -f utils/drive


bin:
	mkdir bin
