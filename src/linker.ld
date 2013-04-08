ENTRY(start)

/* kernel offset in memory (here higher half) */
ker_off = 0xc0000000;

SECTIONS
{
    . = 0x0;

    .text ker_off : AT(ker_off)
    {
        code = .;
        *(.text)
        *(.rodata)

        . = ALIGN(0x10);
    }

    .data : AT(ker_off + (data - code))
    {
        data = .;
        *(.data)
        . = ALIGN(0x10);
    }

    .bss : AT(ker_off + (bss - code))
    {
        bss = .;
        *(.bss)
        . = ALIGN(0x10);
    }

    ker_end = .;
}
