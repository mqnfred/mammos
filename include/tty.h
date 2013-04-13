#ifndef TTY_H
# define TTY_H

# include <stdlib.h>
# include <heap.h>

# define FB_IDX(r, c) (((r) * max_cols + (c)) * 2)


void setup_tty(void);


void write_tty(char* src, uint32_t size);


#endif // !TTY_H
