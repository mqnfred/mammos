#include <frames.h>


static uint32_t* bitmap = NULL;
static uint32_t frame_count = 0;


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


void alloc_frame(struct page* pg, bool is_kernel, bool is_writeable)
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


__attribute__((unused))
void free_frame(struct page* pg)
{
    uint32_t frame = pg->frame;

    if (frame == 0x0)
        return;

    clear_frame(frame);
    pg->frame = 0x0;
}


void setup_frame_management(uint32_t mem_size)
{
    frame_count = mem_size / PAGE_SIZE;
    bitmap = kalloc(PAGE_TO_BYTE(frame_count), 0, NULL);
    memset(bitmap, 0, PAGE_TO_BYTE(frame_count));
}
