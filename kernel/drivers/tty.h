#ifndef TTY_H
# define TTY_H

# include <lib/system.h>
# include <lib/heap.h>

# define FB_IDX(r, c) (((r) * max_cols + (c)) * 2)


void setup_tty(void);
void write_tty(char* src, uint32_t size);


#endif // !TTY_H
