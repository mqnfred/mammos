#include <idt.h>


static struct idt_entry* idt = NULL;


void add_isr(int no, uint32_t ba, uint16_t sel, uint8_t flags)
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
    // initialize on top of the constant heap
    idt = kalloc(256 * sizeof (struct idt_entry), 0x8, 0x0);
    memset(idt, 0, 256 * sizeof (struct idt_entry));

    struct idt_ptr ptr =
    {
        256 * sizeof (struct idt_entry) - 1,
        (uint32_t)idt,
    };

    // setup the idt address in the idt register
    flush_idt(&ptr);

    // setup the basic IST routines
    add_isr(0, (uint32_t)div_zero_exception, 0x08, 0x8E);
}
