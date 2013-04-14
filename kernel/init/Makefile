OBJDIR	= ../objs


all: $(OBJDIR)
	nasm -f elf -g -o $(OBJDIR)/asm_entry.o entry.asm
	nasm -f elf -g -o $(OBJDIR)/asm_isr.o isr.asm
	
	gcc -I../ $(CFLAGS) -c -o $(OBJDIR)/frames.o frames.c
	gcc -I../ $(CFLAGS) -c -o $(OBJDIR)/gdt.o gdt.c
	gcc -I../ $(CFLAGS) -c -o $(OBJDIR)/idt.o idt.c
	gcc -I../ $(CFLAGS) -c -o $(OBJDIR)/kheap.o kheap.c
	gcc -I../ $(CFLAGS) -c -o $(OBJDIR)/paging.o paging.c


$(OBJDIR):
	mkdir -p $(OBJDIR)
