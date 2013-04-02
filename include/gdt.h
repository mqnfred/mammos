#ifndef GDT_H
# define GDT_H

# include <stdint.h>
# include <stdlib.h>
# include <kheap.h>


struct gdt_entry
{
    uint16_t limit_low;
    uint16_t base_low;
    uint8_t base_middle;
    uint8_t access;
    uint8_t granularity;
    uint8_t base_high;
} __attribute__((packed));


struct gdt_ptr
{
    uint16_t limit;
    uint32_t base;
} __attribute__((packed));


extern void flush_gdt(struct gdt_ptr* ptr);
void setup_gdt(void);


#endif // !GDT_H
