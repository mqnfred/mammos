#include <gdt.h>


static struct gdt_entry* gdt = NULL;


static void add_entry(int no, uint64_t ba, uint64_t li, uint8_t ac, uint8_t gr)
{
    // setup base
    gdt[no].base_low = ba & 0xFFFF;
    gdt[no].base_middle = (ba >> 16) & 0xFF;
    gdt[no].base_high = (ba >> 24) & 0xFF;

    // setup limit
    gdt[no].limit_low = li & 0xFFFF;;
    gdt[no].granularity = (li >> 16) & 0x0F;

    // setup granularity and accesses
    gdt[no].granularity |= (gr & 0xF0);
    gdt[no].access = ac;
}


void setup_gdt(void)
{
    // setup gdt on top of kernel heap
    gdt = kalloc(3 * sizeof (struct gdt_entry), 0x8, 0x0);
    memset(gdt, 0, 3 * sizeof (struct gdt_entry));

    struct gdt_ptr ptr =
    {
        3 * sizeof (struct gdt_entry) - 1,
        (uint32_t)gdt,
    };

    // null segment descriptor
    add_entry(0, 0, 0, 0, 0);

    // kernel cs
    add_entry(1, 0x0, 0xFFFFFFFF, 0x9A, 0xCF);

    // kernel ds/es/fs/gs/ss
    add_entry(2, 0x0, 0xFFFFFFFF, 0x92, 0xCF);

    // setup the gdt in the lgdt register
    flush_gdt(&ptr);
}
