#ifndef PAGING_H
# define PAGING_H

# include <stdint.h>
# include <stdlib.h>
# include <kheap.h>
# include <frames.h>


struct page_table
{
    struct page pages[0x400];
};


 struct page_dir
{
    struct page_table* tables[0x400];
    uint32_t tables_phys_addr[0x400];
    uint32_t physicalAddr;
};


void mmap(void* addr);
void setup_mem(uint32_t mem_size);
void switch_page_dir(struct page_dir *new_dir);


#endif // !PAGING_H
