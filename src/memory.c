#include <memory.h>


static struct page_dir* ker_dir = NULL;
static struct page_dir* cur_dir = NULL;
static uint32_t* bitmap = NULL;

static uint32_t freemem_offset = 0x0;
static uint32_t frame_count = 0;


static void* kalloc(uint32_t size, bool align, uint32_t* phys)
{
    if (align && freemem_offset % PAGE_SIZE != 0)
        freemem_offset += PAGE_SIZE - (freemem_offset % PAGE_SIZE);

    void* tmp = (void*)freemem_offset;
    if (phys)
        *phys = freemem_offset;

    freemem_offset += size;
    return tmp;
}


__attribute__((always_inline))
static inline void set_frame(uint32_t addr)
{
    bitmap[INDEX(addr)] |= (1 << OFFSET(addr));
}


__attribute__((always_inline))
static inline void clear_frame(uint32_t addr)
{
    bitmap[INDEX(addr)] &= ~(0x1 << OFFSET(addr));
}


__attribute__((unused))
static inline bool test_frame(uint32_t addr)
{
    return (bitmap[INDEX(addr)] >> OFFSET(addr)) & 0x1;
}


static uint32_t first_frame(void)
{
    // look for the first clear bit (meaning  clear page)
    for (uint32_t i = 0; i < PAGE_TO_UINT32(frame_count); i++)
    {
        if (bitmap[i] == 0xFFFFFFFF)
            continue;

        for (uint8_t j = 0; j < 32; j++)
            if (((bitmap[i] >> j) & 0x1) == 0)
                return ADDR(i, j);
    }

    // invalid address value, since not 4kiB aligned
    return 0x1;
}


static void alloc_frame(struct page* pg, bool is_kernel, bool is_writeable)
{
    if (pg->frame != 0x0)
        return;

    uint32_t addr = first_frame();

    // non-aligned value
    if (addr == 0x1)
        return;

    set_frame(addr);
    pg->present = true;
    pg->rw = (is_writeable ? true : false);
    pg->user = (is_kernel ? false : true);
    pg->frame = addr / PAGE_SIZE;
}


static void free_frame(struct page* pg)
{
    uint32_t frame = pg->frame;

    if (frame == 0x0)
        return;

    clear_frame(frame);
    pg->frame = 0x0;
}


__attribute__((always_inline))
static inline void activate_paging(void)
{
    uint32_t cr0;
    __asm__ volatile("mov %%cr0, %0" : "=r" (cr0));
    cr0 |= 0x80000000;
    __asm__ volatile("mov %0, %%cr0" : : "r" (cr0));
}


void setup_mem(uint32_t mem_size, uint32_t stack_offset)
{
    frame_count = mem_size / PAGE_SIZE;
    freemem_offset = stack_offset;

    bitmap = kalloc(PAGE_TO_BYTE(frame_count), false, NULL);
    memset(bitmap, 0, PAGE_TO_BYTE(frame_count));

    cur_dir = ker_dir = kalloc(sizeof (struct page_dir), true, NULL);

    uint32_t addr = 0;
    while (addr <= freemem_offset)
    {
        alloc_frame(get_page(addr, true, ker_dir), false, false);
        addr += PAGE_SIZE;
    }

    switch_page_dir(ker_dir);
    activate_paging();
}


__attribute__((always_inline))
void switch_page_dir(struct page_dir* new_dir)
{
    cur_dir = new_dir;
    __asm__ volatile("mov %0, %%cr3" : : "r"(&new_dir->tables_phys_addr));
}


struct page* get_page(uint32_t address, bool make, struct page_dir* dir)
{
    uint32_t index = (address /= PAGE_SIZE) / 0x400;

    if (dir->tables[index])
        return &dir->tables[index]->pages[address % 0x400];
    else if(make)
    {
        uint32_t tmp;
        dir->tables[index] = kalloc(sizeof(struct page_table), true, &tmp);
        dir->tables_phys_addr[index] = tmp | 0x7;
        return &dir->tables[index]->pages[address % 0x400];
    }

    return 0x0;
}
