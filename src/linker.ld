OUTPUT_FORMAT("binary")
ENTRY(start)
phys = 0x100000;

SECTIONS
{
    . = 0x0;

    .text phys : AT(phys)
    {
        code = .;
        *(.text)
        *(.rodata)

        . = ALIGN(0x10);
    }

    .data : AT(phys + (data - code))
    {
        data = .;
        *(.data)
        . = ALIGN(0x10);
    }

    .bss : AT(phys + (bss - code))
    {
        bss = .;
        *(.bss)
        . = ALIGN(0x10);
    }

    end = .;
}
