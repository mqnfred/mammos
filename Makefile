include Makefile.inc

all: bootloader kernel

bootloader: $(SRCDIR)$(BOOT_SRC) $(BINDIR)
	$(AS) $< -o $(BOOT_BIN)

kernel: bootloader $(OBJS) $(BINDIR)
	$(LD) $(LDFLAGS) -T $(SRCDIR)$(LD_SRC) $(OBJS) -o $(KERN_BIN) --oformat binary
	chmod a-x $(KERN_BIN)

$(OBJDIR)%.o: $(SRCDIR)%.c $(OBJDIR)
	$(CC) $(CFLAGS) -c -o $@ $<
	$(CPY) $(CPYFLAGS) $@ $@

$(OBJDIR)asm_%.o: $(SRCDIR)%.asm $(OBJDIR)
	$(AS) $(ASFLAGS) -o $@ $<

drive: $(TABLE)
	dd if=/dev/zero bs=1M count=64 of=$(DRIVE)
	dd if=$(TABLE) of=$(DRIVE) bs=1 count=512 conv=notrunc

floppy: drive bootloader kernel
	dd if=$(BOOT_BIN) of=$(DRIVE) bs=1 count=440 conv=notrunc
	dd if=$(KERN_BIN) of=$(DRIVE) bs=512 seek=1 count=2047 conv=notrunc

$(OBJDIR):
	mkdir $(OBJDIR)

$(BINDIR):
	mkdir $(BINDIR)

clean:
	rm -rf $(OBJDIR)

distclean: clean
	rm -rf $(BINDIR) $(DRIVE)

debug:
	$(LD) $(LDFLAGS) -T $(SRCDIR)$(LD_SRC) $(OBJS) -o $(KERN_ELF)
	chmod a-x $(KERN_ELF)

check: floppy
	$(EM) $(DRIVE)

test: debug floppy
	$(EM) $(EMFLAGS) $(DRIVE) 2>&1 1>/dev/null &
	sleep 0.5
	$(DB) $(DBFLAGS) -x $(DB_SCRIPT) -s $(KERN_ELF)
	reset
