include Makefile.inc

all: bootloader kernel

bootloader: $(SRCDIR)$(BOOT_SRC) $(BINDIR)
	$(AS) $< -o $(BINDIR)$(BOOT_BIN)

kernel: bootloader $(OBJS) $(BINDIR)
	$(LD) $(LDFLAGS) -T $(SRCDIR)$(LD_SRC) $(OBJS) -o $(BINDIR)$(KERN_BIN)
	chmod a-x $(BINDIR)$(KERN_BIN)

$(OBJDIR)%.o: $(SRCDIR)%.c $(OBJDIR)
	$(CC) $(CFLAGS) -c -o $@ $<
	$(CPY) $(CPYFLAGS) $@ $@

$(OBJDIR)asm_%.o: $(SRCDIR)%.asm $(OBJDIR)
	$(AS) $(ASFLAGS) -o $@ $<

drive: $(TABLE)
	dd if=/dev/zero bs=1M count=64 of=$(DRIVE)
	dd if=$(TABLE) of=$(DRIVE) bs=1 count=512 conv=notrunc

floppy: drive bootloader kernel
	dd if=$(BINDIR)$(BOOT_BIN) of=$(DRIVE) bs=1 count=440 conv=notrunc
	dd if=$(BINDIR)$(KERN_BIN) of=$(DRIVE) bs=512 seek=1 count=2047 conv=notrunc

$(OBJDIR):
	mkdir $(OBJDIR)

$(BINDIR):
	mkdir $(BINDIR)

clean:
	rm -rf $(OBJDIR)

distclean: clean
	rm -rf $(BINDIR) $(DRIVE)

check: floppy
	$(EM) $(EMFLAGS) $(DRIVE) 2>&1 1>/dev/null &
	$(DB)
