#include <stage2/fs/minix.h>

# define BLOCK_SIZE 1024
# define S_IFDIR 0x4000 // as per standart


static struct minix_fs fs;


static void *
tmp_block(uint32_t offset)
{
    // avoid wasting precious heap memory, use the same space for all
    // temporary handling of blocks
    static struct minix_inode *block = 0x0;

    if (block == 0x0)
        block = malloc(BLOCK_SIZE);

    disk_read(fs.part->s_lba + offset * 2, 2, block);
    return block;
}


static struct minix_inode *
tmp_inode(uint32_t inode_offset)
{
    // be careful, trashes the tmp block to retrieve an inode
    uint32_t boff = (fs.itable_boff + inode_offset / MINIX_INODES_PER_BLOCK);
    struct minix_inode *itable = tmp_block(boff);
    return itable + inode_offset % MINIX_INODES_PER_BLOCK;
}


__attribute__((always_inline)) inline static uint16_t
scan_folder(const char *name, struct minix_dir_entry *dir_entries)
{
    // returns the index of the given directory in the inode table
    char *tmp = (char *) dir_entries;

    // considering the sizeof (struct minix_dir_entry) isn't available
    // since its size varies (15 or 31 bytes, depending on filename sizes)
    // we have to use some bytewise operations to run through the directories
    for (uint16_t i = 0; i < (BLOCK_SIZE / fs.drsize); i += 1)
        if (strcmp(name, tmp + i * fs.drsize + 2) == 0)
            // -1 since the inode indexing starts at 1
            return *(tmp + i * fs.drsize) - 1;

    // 0xFFFF is the maximum value, unlikely to be dealt with
    return 0xFFFF;
}


__attribute__((always_inline)) static inline uint16_t
is_directory(struct minix_inode *inode)
{
    return (inode->i_mode & S_IFDIR);
}


static struct minix_inode *
get_file_inode(const char *path)
{
    struct minix_inode *inode = &fs.root_inode;
    struct minix_dir_entry *tmp;
    uint16_t ioff;

    const char **folders = (const char **) split(path, '/');

    for (uint8_t fd = 0; folders[fd] != 0x0 || ioff == 0xFFFF; fd += 1)
    {
        // 2 possibilities: the directory was not found and the inode found
        // is not a directory but is treated as a subdirectory
        if (!is_directory(inode))
            PANIC(path, "not a directory")
        else if (ioff == 0xFFFF)
            PANIC(path, "file or directory not found")

        for (uint8_t i = 0; i < 7; i += 1)
        {
            // load each zone of the current directory
            tmp = tmp_block(inode->i_zone[i]);

            // if the current directory does not contain our next directory
            // or file, go on to the next zone
            ioff = scan_folder(folders[fd], tmp);
            if (ioff == 0xFFFF)
                continue;

            // otherwise we found our next directory/file
            inode = tmp_inode(ioff);
            break;
        }
    }

    return inode;
}


static uint32_t
load_datazone(uint32_t boff, void *dst, uint32_t amount)
{
    if (amount >= BLOCK_SIZE)
        disk_read(fs.part->s_lba + boff * 2, 2, dst);
    else
        memcpy(dst, tmp_block(boff), amount);

    return amount;
}


__attribute__((always_inline)) inline static void
load_indirects(uint16_t ib_index, uint32_t bytes_left, void *dst)
{
    uint16_t *indexes = calloc(512, sizeof (uint16_t));
    disk_read(fs.part->s_lba + ib_index * 2, 2, indexes);

    for (uint32_t b = 0; b < 512 && indexes[b] != 0 && bytes_left > 0; b += 1)
    {
        load_datazone(indexes[b], dst, bytes_left);

        dst = (void *) ((uint32_t) dst + BLOCK_SIZE);
        bytes_left -= (bytes_left > BLOCK_SIZE ? BLOCK_SIZE : bytes_left);
    }
}


void
minix_init(struct part_entry *part)
{
    // get over the boot block, offset 1
    uint32_t offset = 1;
    fs.part = part;

    // load superblock in memory and analyze it
    disk_read(fs.part->s_lba + offset++ * 2, 1, fs.super = malloc(512));
    fs.drsize = (fs.super->s_magic == MINIX_SUPER_MAGIC ? 16 : 32);

    // process offset of itabledepending on i/zmap sizes
    offset += fs.super->s_imap_blocks + fs.super->s_zmap_blocks;

    // load the first block of the inode table to retrieve the root inode
    // (inode 0 of the first inode table)
    struct minix_inode *tmp = tmp_block(fs.itable_boff = offset);
    fs.root_inode = tmp[0];
}


uint32_t
minix_get_size(const char *path)
{
    // useful when reading a file on the heap (need a malloc beforehand)
    struct minix_inode *inode = get_file_inode(path);
    return inode->i_size;
}


// TODO handle loading of files of size >(7 + 512)*1024
// TODO: handle loading of directories of size >(7 * 1024 bytes)
uint32_t
minix_load_file(const char *path, void *dst)
{
    struct minix_inode *inode = get_file_inode(path);
    uint32_t bytes_left = inode->i_size;

    // if there is more than what we can store in the direct blocks, panic
    if (bytes_left > ((7 + 512) * 1024))
        PANIC(path, "files this big are not yet supported")

    // load only the direct blocks
    for (uint32_t b = 0; b < 7 && bytes_left > 0; b += 1)
    {
        bytes_left -= load_datazone(inode->i_zone[b], dst, bytes_left);
        dst = (void *) ((uint32_t) dst + BLOCK_SIZE);
    }

    // TODO: debug this
    if (bytes_left > 0 && inode->i_zone[7] != 0)
        load_indirects(inode->i_zone[7], bytes_left, dst);
    else if (bytes_left > 0)
        DEBUG("bytes left but no indirect blocks left");

    // return the number of bytes read
    return inode->i_size;
}
