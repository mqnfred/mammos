INPUT(stage1.o);
OUTPUT(stage1.elf);
ENTRY(stage1);


stage2 = 0x7E00;
mbr_magic = 0xAA55;
chunk_offset = 0x500;


SECTIONS
{
    . = 0x0;

    mbr 0x7C00 : AT(0x7C00)
    {
        *(.text);
        *(.data);
    }
}
