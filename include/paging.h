#ifndef PAGING_H
# define PAGING_H

# include <stdint.h>
# include <stdlib.h>
# include <kheap.h>

# define PAGE_SIZE              (0x1000)

# define PAGE_TO_BYTE(sz)       (sz / 8)
# define PAGE_TO_UINT32(sz)     (sz / 32)

# define ADDR(in, off)          (in * PAGE_SIZE * 32 + off * PAGE_SIZE)
# define INDEX(addr)            (addr / (PAGE_SIZE * 32))
# define OFFSET(addr)           ((addr / PAGE_SIZE) % 32)


struct page
{
    uint32_t present    : 1;
    uint32_t rw         : 1;
    uint32_t user       : 1;
    uint32_t accessed   : 1;
    uint32_t dirty      : 1;
    uint32_t unused     : 7;
    uint32_t frame      : 20;
};


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


void setup_mem(uint32_t mem_size, uint32_t stack_offset);
void switch_page_dir(struct page_dir *new_dir);
struct page *get_page(uint32_t address, bool make, struct page_dir* dir);


#endif // !PAGING_H
