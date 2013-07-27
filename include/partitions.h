#ifndef PARTITIONS_H
# define PARTITIONS_H

# include <stdint.h>


struct part_entry
{
    uint8_t bootable;

    uint8_t s_head;
    uint16_t s_sector : 6;
    uint16_t s_cyl : 10;

    uint8_t system_id;

    uint8_t e_head;
    uint16_t e_sector : 6;
    uint16_t e_cyl : 10;

    uint32_t s_lba;
    uint32_t sectors_c;
} __attribute__((packed));


#endif // !PARTITIONS_H
