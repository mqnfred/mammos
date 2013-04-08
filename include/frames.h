#ifndef FRAMES_H
# define FRAMES_H

# include <stdint.h>
# include <stdlib.h>
# include <kheap.h>

# define PAGE_SIZE              (0x1000)

# define PAGE_TO_BYTE(sz)       (sz / 8)
# define PAGE_TO_UINT32(sz)     (sz / 32)

# define ADDR_FROM_IDX(in, off) (in * PAGE_SIZE * 32 + off * PAGE_SIZE)
# define IDX_FROM_ADDR(addr)    (addr / (PAGE_SIZE * 32))
# define OFFSET_FROM_ADDR(addr) ((addr / PAGE_SIZE) % 32)


void setup_frames(uint32_t mem_size);


uint32_t alloc_frame(void);
bool alloc_spec_frame(uint32_t addr);
void free_frame(uint32_t addr);


#endif // !FRAMES_H
