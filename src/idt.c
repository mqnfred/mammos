#include <idt.h>


static struct idt_entry idt[255] = { { 0 } };


static void add_entry(int no, uint64_t ba, uint16_t sel, uint8_t flags)
{
    // setup the base and segment selector of the routine
    idt[no].base_low = ba & 0xFFFF;
    idt[no].base_high = (ba >> 16) & 0xFFFF;
    idt[no].sel = sel;

    // setup flags, the zero field is not used
    idt[no].zero = 0x0;
    idt[no].flags = flags;
}


void setup_idt(void)
{
    struct idt_ptr ptr =
    {
        sizeof (idt) - 1,
        (uint32_t)&idt,
    };

    // setup the idt address in the idt register
    flush_idt(&ptr);

    // setup the basic IST routines
    add_entry(0, (uint64_t)div_zero_exception, 0x08, 0x8E);
}
