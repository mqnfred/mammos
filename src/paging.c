#include <paging.h>


static struct page_dir* ker_dir = NULL;
static struct page_dir* cur_dir = NULL;


__attribute__((always_inline))
static inline void switch_page_dir(struct page_dir* new_dir)
{
    cur_dir = new_dir;
    __asm__ volatile("mov %0, %%cr3" : : "r" (&new_dir->tables));
}


__attribute__((always_inline))
static inline void activate_paging(void)
{
    uint32_t cr0;
    __asm__ volatile("mov %%cr0, %0" : "=r" (cr0));
    cr0 |= 0x80000000;
    __asm__ volatile("mov %0, %%cr0" : : "r" (cr0));
}


void setup_paging(void)
{
    // setup kernel directory as well as the first page table in the
    // directory, they will identity map the low-memory, the kernel and
    // everything up to themselves (included)
    ker_dir = init_kmalloc(PAGE_SIZE, PAGE_SIZE, 0x0);
    ker_dir->tables[0] = init_kmalloc(PAGE_SIZE, PAGE_SIZE, 0x0);
    ker_dir->tables[0] = (void*)((uint32_t)ker_dir->tables[0] | 0x7);
    for (uint32_t i = 0x0; i < freemem_offset; i += PAGE_SIZE)
    {
        struct page_table* ptr = ker_dir->tables[0];
        ptr = (void*)((uint32_t)ptr & 0xFFFFF000);
        ptr->pages[i / PAGE_SIZE] = alloc_frame() | 0x7;
    }

    // allocate the frames for the remainding page tables
    for (uint16_t i = 1; i < 1023; i += 1)
        ker_dir->tables[i] = (void*)(alloc_frame() | 0x7);
    ker_dir->tables[1023] = (void*)((uint32_t)ker_dir | 0x7);

    // finally activate paging
    switch_page_dir(ker_dir);
    activate_paging();
}


__attribute__((always_inline))
static inline uint32_t* get_page_entry_address(uint32_t address)
{
    address /= PAGE_SIZE;
    struct page_table* pgt = (void*)0xFFC00000;
    pgt += address / 1024;
    return &pgt->pages[address % 1024];
}


void mmap(uint32_t address)
{
    uint32_t* page_entry = get_page_entry_address(address);

    // map it only if it is not mapped already
    if (*page_entry == 0x0)
        *page_entry = (alloc_frame() & 0xFFFFF000) | 0x7;
}


void munmap(uint32_t address)
{
    uint32_t* page_entry = get_page_entry_address(address);

    // unmap it only if it is mapped already
    if (*page_entry != 0x0)
    {
        free_frame(*page_entry & 0xFFFFF000);
        *page_entry = 0x0;
    }
}
