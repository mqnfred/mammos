#ifndef FAT_H
# define FAT_H

# include <stdint.h>
# include <fs/fat.h>
# include <partitions.h>
# include <stage2/utils/disk.h>
# include <stage2/utils/tools.h>


struct fat_fs
{
    // current partition and filesystem bpb (superblock)
    struct part_entry *part;
    struct fat_bpb *bpb;

    // file allocation tables and root directory entries
    uint16_t *tables;
    struct fat_dir_entry *root;

    // offset of the first datacluster in the partition and a cluster size
    uint32_t fdataclust;
    uint32_t csize;
    enum fat_type type;
};


void fat_init(struct part_entry *part);
uint32_t fat_load_file(const char *path, void *dst);
uint32_t fat_get_size(const char *path);


#endif // !FAT_H
