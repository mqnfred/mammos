#include <stdlib.h>
#include <heap.h>


__attribute__((noreturn))
void kmain(void)
{
    uint32_t* r = (void*)0x800000;
    *r = 9;

    while (1);
}
