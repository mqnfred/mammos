#ifndef KHEAP_H
# define KHEAP_H

# include <stdint.h>
# include <stdlib.h>


extern uint32_t kernel_end;
extern uint32_t freemem_offset;


void setup_frames(uint32_t mem_size);
void* kalloc(uint32_t size, uint32_t align, uint32_t* phys);


#endif // !KHEAP_H
