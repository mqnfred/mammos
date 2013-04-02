# include <kheap.h>


// the "top" of the heap is at the far end of the kernel code/data segments
// this is denoted by kernel_end, symbol defined by the linker.ld file
extern uint32_t kernel_end;
uint32_t freemem_offset = (uint32_t)&kernel_end;


void* kalloc(uint32_t size, uint32_t align, uint32_t* phys)
{
    if (align != 0 && freemem_offset % align != 0)
        freemem_offset += align - (freemem_offset % align);

    void* tmp = (void*)freemem_offset;
    if (phys)
        *phys = freemem_offset;

    freemem_offset += size;
    return tmp;
}
