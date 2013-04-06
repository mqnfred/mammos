#include <stdlib.h>
#include <paging.h>


__attribute__((noreturn))
void kmain(void)
{
    mmap(freemem_offset);
    munmap(freemem_offset);
    mmap(freemem_offset);

    while (1);
}
