#ifndef DISK_H
# define DISK_H


extern void disk_read(uint32_t lba, uint32_t sectors_nbr, void* dst);
extern void disk_write(uint32_t lba, uint32_t sectors_nbr, void* src);


#endif // !DISK_H
