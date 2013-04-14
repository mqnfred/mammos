ENTRY(start)


mbr_magic = 0xaa55;

stage1_offset = 0x7c00;
stage2_offset = 0x7e00;

data_offset = 0x500;
stack_offset = stage1_offset - 0xf0;
chunk_offset = 0x700;

kernel_offset = 0xc0000000;


SECTIONS
{
    . = 0x0;

    mbr stage1_offset : AT(stage1_offset)
    {
        objs/mbr.o(.text);
        objs/mbr.o(.data);

        . = 0x1fe;
        SHORT(mbr_magic);
    }
    . = 0x200;

    ebr stage2_offset : AT(stage2_offset)
    {
        objs/ebr.o(.text);
        objs/ebr.o(.data);
    }
}
