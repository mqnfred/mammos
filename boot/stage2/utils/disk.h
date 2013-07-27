#ifndef DISK_H
# define DISK_H

# include <stdint.h>


extern void disk_read(uint32_t lba, uint32_t sectors_count, void* dst);


#endif // !DISK_H
