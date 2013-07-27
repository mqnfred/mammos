#ifndef MINIX_H
# define MINIX_H

# include <partitions.h>
# include <fs/minix.h>
# include <stage2/utils/disk.h>
# include <stage2/utils/tools.h>


struct minix_fs
{
    // current partition and filesystem superblock
    struct part_entry *part;
    struct minix_super_block *super;

    // directory entries size
    uint8_t drsize;

    // root inode and block offset of the inode table (from start of part)
    struct minix_inode root_inode;
    uint16_t itable_boff;
};


void minix_init(struct part_entry *part);
uint32_t minix_load_file(const char *path, void *dst);
uint32_t minix_get_size(const char *path);


#endif // !MINIX_H
