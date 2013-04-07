#ifndef HEAP_H
# define HEAP_H

# include <stdint.h>
# include <stdlib.h>
# include <frames.h>
# include <paging.h>

# define OVERHEAD_TOLERANCE     (sizeof (uint64_t))
# define NODES_IN_PAGE          (PAGE_SIZE / sizeof (struct meta))


struct meta
{
    struct meta* next;

    uint32_t addr;
    uint32_t size;
    uint8_t free;
};


void* malloc(uint32_t size);
void free(void* address);


void setup_heap(uint32_t offset);


#endif // !HEAP_H
