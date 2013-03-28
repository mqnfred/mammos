#include <gdt.h>
#include <idt.h>


void kmain(void)
{
    setup_gdt();
    setup_idt();
    setup_irq();

    int a = 12;
    int b = 1;

    int c = a / b;

    (void)c;

    while (1);
}
