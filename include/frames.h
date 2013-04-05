#ifndef FRAMES_H
# define FRAMES_H

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



void setup_frame_management(uint32_t mem_size);
void alloc_frame(struct page* pg, bool is_kernel, bool is_writeable);
void free_frame(struct page* pg);


#endif // !FRAMES_H
