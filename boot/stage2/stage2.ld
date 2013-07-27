INPUT
(
    fs/minix.o
    fs/fat.o
    utils/disk.o
    utils/tools.o
);


OUTPUT(stage2.elf);
STARTUP(stage2.o);
ENTRY(stage2);


ebda_start = 0x80000;
chunk_offset = 0x500;


SECTIONS
{
    . = 0x0;

    .text 0x7E00 : AT(0x7E00)
    {
        *(.text);
        *(.rodata);
    }

    .data :
    {
        *(.data);
        *(.bss);
    }

    . = ALIGN(4096);
    stage2_end = .;
}
