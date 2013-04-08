#include <paging.h>


static struct page_dir* ker_dir = NULL;
static struct page_dir* cur_dir = NULL;

static uint32_t* const pagedir = (void*)0xFFFFF000;


__attribute__((always_inline))
static inline void switch_page_dir(struct page_dir* new_dir)
{
    cur_dir = new_dir;
    __asm__ volatile("mov %0, %%cr3" : : "r" (&new_dir->tables));
}


static void activate_paging(void)
{
    uint32_t cr0;
    __asm__ volatile("mov %%cr0, %0" : "=r" (cr0));
    cr0 |= 0x80000000;
    __asm__ volatile("mov %0, %%cr0" : : "r" (cr0));
}


void setup_paging(void)
{
    // setup kernel directory
    // and recursively link it to itself
    ker_dir = init_kmalloc(PAGE_SIZE, PAGE_SIZE, 0x0);
    memset(ker_dir, 0, sizeof (struct page_dir));
    ker_dir->tables[1023] = (void*)((uint32_t)ker_dir | 0x7);

    // setup the first 4MB page table and
    // identity map the low memory (first 1MB)
    ker_dir->tables[0] = init_kmalloc(PAGE_SIZE, PAGE_SIZE, 0x0);
    ker_dir->tables[0] = (void*)((uint32_t)ker_dir->tables[0] | 0x7);
    for (uint32_t i = 0x0; i < 0x100000; i += PAGE_SIZE)
    {
        struct page_table* ptr = ker_dir->tables[0];
        ptr = (void*)((uint32_t)ptr & 0xFFFFF000);

        if (alloc_spec_frame(i))
            ptr->pages[(i / PAGE_SIZE) % 1024] = i | 0x7;
        else
            while (1);
    }

    // identity map the kernel from 0xc0000000 to freemem_offset
    for (uint32_t i = (uint32_t)&ker_off; i < freemem_offset; i += PAGE_SIZE)
    {

        // get page table index and get a pointer to it in the directory
        uint32_t pgtbl_idx = i / PAGE_SIZE / 1024;
        struct page_table* ptr;

        // create the page table if it does not already exists
        if (ker_dir->tables[pgtbl_idx] == 0x0)
        {
            ker_dir->tables[pgtbl_idx] = (void*)(alloc_frame() | 0x7);

            // memset the new page table
            ptr = (void*)((uint32_t)ker_dir->tables[pgtbl_idx] & 0xFFFFF000);
            memset(ptr, 0, sizeof (struct page_table));
        }
        else
            ptr = (void*)((uint32_t)ker_dir->tables[pgtbl_idx] & 0xFFFFF000);

        // once the page table is present, setup the page table entry in it
        if (alloc_spec_frame(i))
            ptr->pages[(i / PAGE_SIZE) % 1024] = i | 0x7;
        else
            while (1);
    }

    // finally activate paging
    switch_page_dir(ker_dir);
    activate_paging();
}


void mmap(uint32_t address)
{
    uint32_t pgtbl_idx = (address /= PAGE_SIZE) / 1024;
    uint32_t pg_idx = address % 1024;
    struct page_table* pgtbl = (void*)0xFFC00000;

    pgtbl = (void*)((uint32_t)pgtbl + pgtbl_idx * sizeof (struct page_table));

    // allocate space for the page table
    // if it does not exist already
    if (pagedir[pgtbl_idx] == 0x0)
    {
        pagedir[pgtbl_idx] = (alloc_frame() & 0xFFFFF000) | 0x7;
        memset(pgtbl, 0, sizeof (struct page_table));
    }

    // map it only if it is not mapped already
    if (pgtbl->pages[pg_idx] == 0x0)
         pgtbl->pages[pg_idx] = (alloc_frame() & 0xFFFFF000) | 0x7;
}


void munmap(uint32_t address)
{
    uint32_t pgtbl_idx = (address /= PAGE_SIZE) / 1024;
    uint32_t pg_idx = address % 1024;
    struct page_table* pgtbl = (void*)0xFFC00000;

    pgtbl = (void*)((uint32_t)pgtbl + pgtbl_idx * sizeof (struct page_table));

    // unmap it only if it is mapped already
    if (pgtbl->pages[pg_idx] != 0x0)
    {
        free_frame(pgtbl->pages[pg_idx] & 0xFFFFF000);
        pgtbl->pages[pg_idx] = 0x0;
    }
}
