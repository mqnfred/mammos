#ifndef KHEAP_H
# define KHEAP_H

# include <stdint.h>


void* kalloc(uint32_t size, uint32_t align, uint32_t* phys);


extern uint32_t freemem_offset;


#endif // !KHEAP_H
