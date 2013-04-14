OBJDIR	= ../objs


all: $(OBJDIR)
	gcc -I../ $(CFLAGS) -c -o $(OBJDIR)/heap.o heap.c
	gcc -I../ $(CFLAGS) -c -o $(OBJDIR)/stdlib.o stdlib.c
	gcc -I../ $(CFLAGS) -c -o $(OBJDIR)/system.o system.c


$(OBJDIR):
	mkdir -p $(OBJDIR)
