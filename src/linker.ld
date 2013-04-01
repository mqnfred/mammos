ENTRY(start)

kernel_offset = 0x100000;
stack_offset = 0x200000;
memory_size = 0x400 * 0x400 * 0x10;

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
