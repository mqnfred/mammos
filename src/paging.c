#include <paging.h>


static struct page_dir* ker_dir = NULL;
static struct page_dir* cur_dir = NULL;


static struct page* get_page(uint32_t address, bool make, struct page_dir* dir)
{
    uint32_t idx = (address /= PAGE_SIZE) / 0x400;

    if (dir->tables[idx])
        return &dir->tables[idx]->pages[address % 0x400];
    else if(make)
    {
        uint32_t tmp;
        dir->tables[idx] = kalloc(sizeof (struct page_table), PAGE_SIZE, &tmp);
        dir->tables_phys_addr[idx] = tmp | 0x7;
        return &dir->tables[idx]->pages[address % 0x400];
    }

    return 0x0;
}


__attribute__((always_inline))
inline void switch_page_dir(struct page_dir* new_dir)
{
    cur_dir = new_dir;
    __asm__ volatile("mov %0, %%cr3" : : "r" (&new_dir->tables_phys_addr));
}


__attribute__((always_inline))
static inline void activate_paging(void)
{
    uint32_t cr0;
    __asm__ volatile("mov %%cr0, %0" : "=r" (cr0));
    cr0 |= 0x80000000;
    __asm__ volatile("mov %0, %%cr0" : : "r" (cr0));
}


void setup_mem(uint32_t mem_size)
{
    // setup frame management
    setup_frame_management(mem_size);

    // setup kernel directory
    ker_dir = kalloc(sizeof (struct page_dir), PAGE_SIZE, NULL);

    // setup page tables and page entries for identity mapping
    for (uint32_t addr = 0; addr < freemem_offset; addr += PAGE_SIZE)
        mmap((void*)addr);

    switch_page_dir(ker_dir);
    activate_paging();
}


void mmap(void* addr)
{
    alloc_frame(get_page((uint32_t)addr, true, ker_dir), false, false);
}
