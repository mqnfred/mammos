#include <kheap.h>


uint32_t freemem_offset = (uint32_t)&kernel_end;


// this malloc is to be used ONLY before paging initialization
// memory allocated with the malloc cannot be freed!
void* init_kmalloc(uint32_t size, uint32_t align, uint32_t* phys)
{
    if (align != 0 && freemem_offset % align != 0)
        freemem_offset += align - (freemem_offset % align);

    void* tmp = (void*)freemem_offset;
    if (phys)
        *phys = freemem_offset;

    freemem_offset += size;
    return tmp;
}
