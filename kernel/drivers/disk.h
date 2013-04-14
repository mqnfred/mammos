#ifndef DISK_H
# define DISK_H

# include <lib/heap.h>


enum format
{
    FAT32 = 0xc,
    MINIX = 0x80,
};


struct disk
{
    uint32_t number;
    struct partition* parts;
};


struct partition
{
    bool boot;
    enum format type;

    uint32_t lba;
    uint32_t size;
};


extern void disk_read(uint32_t lba, uint32_t sectors_nbr, void* dst);
extern void disk_write(uint32_t lba, uint32_t sectors_nbr, void* src);


void setup_disks(void);


#endif // !DISK_H
