ENTRY(start)

kernel_offset = 0xc0000000;

SECTIONS
{
    . = 0x0;

    .text kernel_offset : AT(kernel_offset)
    {
        code = .;
        *(.text)
        *(.rodata)

        . = ALIGN(0x10);
    }

    .data : AT(kernel_offset + (data - code))
    {
        data = .;
        *(.data)
        . = ALIGN(0x10);
    }

    .bss : AT(kernel_offset + (bss - code))
    {
        bss = .;
        *(.bss)
        . = ALIGN(0x10);
    }

    kernel_end = .;
}
