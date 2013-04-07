#include <frames.h>


static uint32_t* bitmap = NULL;
static uint32_t frame_count = 0;


__attribute__((always_inline))
static inline void set_frame(uint32_t addr)
{
    bitmap[IDX_FROM_ADDR(addr)] |= (1 << OFFSET_FROM_ADDR(addr));
}


__attribute__((always_inline))
static inline void clear_frame(uint32_t addr)
{
    bitmap[IDX_FROM_ADDR(addr)] &= ~(0x1 << OFFSET_FROM_ADDR(addr));
}


__attribute__((unused))
static inline bool test_frame(uint32_t addr)
{
    return (bitmap[IDX_FROM_ADDR(addr)] >> OFFSET_FROM_ADDR(addr)) & 0x1;
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
                return ADDR_FROM_IDX(i, j);
    }

    // invalid address value, since not 4kiB aligned
    return 0x1;
}


uint32_t alloc_frame(void)
{
    uint32_t addr = first_frame();

    if (addr % PAGE_SIZE != 0)
        return 0x0;

    set_frame(addr);
    return addr;
}


__attribute__((unused))
void free_frame(uint32_t addr)
{
    clear_frame(addr);
}


void setup_frames(uint32_t mem_size)
{
    frame_count = mem_size / PAGE_SIZE;
    bitmap = init_kmalloc(PAGE_TO_BYTE(frame_count), 0, NULL);
    memset(bitmap, 0, PAGE_TO_BYTE(frame_count));
}
