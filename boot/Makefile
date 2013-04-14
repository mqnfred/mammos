OBJDIR	= objs
BIN		= ../bin


all: bootloader


bootloader: $(BIN) $(OBJDIR) mbr.asm ebr.asm boot.ld
	nasm -f elf -g -o $(OBJDIR)/mbr.o mbr.asm
	nasm -f elf -g -o $(OBJDIR)/ebr.o ebr.asm
	ld -melf_i386 --gc-sections -T boot.ld -o $(BIN)/boot.bin --oformat=binary
	ld -melf_i386 --gc-sections -T boot.ld -o $(BIN)/boot.o


$(OBJDIR):
	mkdir -p $(OBJDIR)


$(BIN):
	mkdir -p $(BIN)


clean:
	rm -rf $(OBJDIR)
