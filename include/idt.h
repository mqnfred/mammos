#ifndef IDT_H
# define IDT_H

# include <stdint.h>


struct idt_entry
{
    uint16_t base_low;
    uint16_t sel;
    uint8_t zero;
    uint8_t flags;
    uint16_t base_high;
} __attribute__((packed));


struct idt_ptr
{
    uint16_t limit;
    uint32_t base;
} __attribute__((packed));


extern void flush_idt(struct idt_ptr* ptr);
extern void setup_irq(void);

extern void div_zero_exception(void);
extern void page_fault_exception(void);


void setup_idt(void);


#endif // !IDT_H
