#ifndef KHEAP_H
# define KHEAP_H

# include <stdint.h>
# include <stdlib.h>


extern uint32_t ker_end;
extern uint32_t freemem_offset;


extern void mmap(uint32_t address);
extern void munmap(uint32_t address);


void* init_kmalloc(uint32_t size, uint32_t align, uint32_t* phys);


#endif // !KHEAP_H
