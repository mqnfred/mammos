OBJDIR	= ../objs


all: $(OBJDIR)
	nasm -f elf -g -o $(OBJDIR)/asm_disk.o disk.asm
	
	gcc -I../ $(CFLAGS) -c -o $(OBJDIR)/tty.o tty.c
	gcc -I../ $(CFLAGS) -c -o $(OBJDIR)/disk.o disk.c


$(OBJDIR):
	mkdir -p $(OBJDIR)
