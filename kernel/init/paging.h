#ifndef PAGING_H
# define PAGING_H

# include <init/kheap.h>
# include <init/frames.h>
# include <lib/stdint.h>
# include <lib/stdlib.h>


struct page_table
{
    uint32_t pages[1024];
};


struct page_dir
{
    struct page_table* tables[1024];
};


extern uint32_t ker_off;


void mmap(uint32_t address);
void munmap(uint32_t address);


void setup_paging(void);


#endif // !PAGING_H
