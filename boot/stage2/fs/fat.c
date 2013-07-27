#include <stage2/fs/fat.h>

// cluster capacity, usable only after defining fs.csize (fat_init())
#define CCAP(type) (fs.csize * 512 / sizeof (type))


static struct fat_fs fs;


__attribute__((always_inline)) inline static uint8_t
eof(uint16_t offset)
{
    return offset >= (fs.type == FAT12 ? 0xFF8 : 0xFFF8);
}


// TODO: this function is a hack, look for something more generic
static uint16_t
process_offset(uint16_t off)
{
    if (off != 0)
    {
        off = (off - 2) * fs.csize;
        off += (fs.bpb->bxRootDirEnts * sizeof (struct fat_dir_entry)) / 512;
    }

    return off + fs.fdataclust;
}


static void *
tmp_cluster(uint32_t off)
{
    static void *cluster = 0x0;

    if (cluster == 0x0)
        cluster = malloc(fs.csize * 512);

    // process off more accurately
    off = process_offset(off);

    disk_read(fs.part->s_lba + off, fs.csize, cluster);
    return cluster;
}


__attribute__((unused)) static uint16_t
next_cluster_index(uint16_t offset)
{
    if (fs.type == FAT12)
    {
        uint32_t fat_offset = (offset + (offset / 2)) % fs.csize;

        if (offset & 0x0001)
            return fs.tables[fat_offset] >> 4;
        return fs.tables[fat_offset] & 0x0FFF;
    }
    else if (fs.type == FAT16)
        return fs.tables[offset];
    return 0;
}


// TODO: take into account the 256 bytes datazone holding
// big filenames
__attribute__((always_inline)) inline static uint8_t
match(const char *name, struct fat_long_name_entry *entry)
{
    for (uint32_t i = 0; i < 5; i += 1)
        if (entry->name1[i] != name[i])
            return 0;
        else if (entry->name1[i] == '\0')
            return 1;

    for (uint32_t i = 0; i < 6; i += 1)
        if (entry->name2[i] != name[i + 5])
            return 0;
        else if (entry->name1[i] == '\0')
            return 1;

    for (uint32_t i = 0; i < 2; i += 1)
        if (entry->name2[i] != name[i + 6])
            return 0;
        else if (entry->name1[i] == '\0')
            return 1;

    return 1;
}


__attribute__((always_inline)) inline static struct fat_dir_entry *
scan_folder(const char *name, uint16_t offset)
{
    struct fat_dir_entry *entries = tmp_cluster(offset);
    uint32_t i = 0;

    while (!eof(offset))
    {
        // last entry of the directory, file/directory not found
        if (entries[i].name[0] == 0x00)
            break;
        // long filename entry
        else if (entries[i].attr == 0x0F)
        {
            if (match(name, (struct fat_long_name_entry *) entries + i++))
                return entries + i;
        }
        // standart directory entry
        else if (strcmp(entries[i].name + 1, name) == 0)
            return entries + i;

        if (i++ == CCAP(struct fat_dir_entry))
        {
            i = 0;

            offset = next_cluster_index(offset);
            if (!eof(offset))
                entries = tmp_cluster(offset);
        }
    }

    // no entry was found
    return 0x0;
}


static struct fat_dir_entry *
get_file_direntry(const char *name)
{
    const char **folders = (const char **) split(name, '/');
    struct fat_dir_entry *current = calloc(1, sizeof (struct fat_dir_entry));

    for (uint32_t fd = 0; folders[fd] != 0x0; fd += 1)
        current = scan_folder(folders[fd], current->first_cluster_low);

    struct fat_dir_entry *ret = calloc(1, sizeof (struct fat_dir_entry));
    memcpy(ret, current, sizeof (struct fat_dir_entry));
    return ret;
}


static uint32_t
load_datacluster(uint32_t offset, void *dst, uint32_t amount)
{
    if (amount >= fs.csize * 512)
        disk_read(fs.part->s_lba + process_offset(offset), amount / 512, dst);
    else
        memcpy(dst, tmp_cluster(offset), amount);

    return amount;
}


void
fat_init(struct part_entry *part)
{
    fs.part = part;

    // read the bios parameter block in memory (fat "superblock")
    disk_read(part->s_lba, 1, fs.bpb = malloc(512));

    if (fs.bpb->sector_size != 512)
        PANIC("sector size", "only a 512 bytes sector size is supported")

    fs.fdataclust = fs.bpb->bxResSectors + fs.bpb->bxFATs * fs.bpb->bxFATsecs;
    fs.type = (!strcmp(fs.bpb->fat12_16.fstype, "FAT16   ") ? FAT16 : FAT12);
    fs.csize = fs.bpb->bxSecPerClust;

    // allocate space and load the File Allocation Tables in memory
    uint32_t off = fs.bpb->bxResSectors;
    uint32_t size = fs.bpb->bxFATs * fs.bpb->bxFATsecs;
    disk_read(part->s_lba + off, size, fs.tables = malloc(size * 512));

    // allocate space and load the root directory entries table
    size = fs.bpb->bxRootDirEnts * sizeof (struct fat_dir_entry);
    disk_read(part->s_lba + fs.fdataclust, size / 512, fs.root = malloc(size));
}


uint32_t
fat_get_size(const char *path)
{
    struct fat_dir_entry *file = get_file_direntry(path);

    if (file == 0x0)
        PANIC(path, "file not found")
    return file->file_size;
}


uint32_t
fat_load_file(const char *path, void *dst)
{
    struct fat_dir_entry *file = get_file_direntry(path);

    if (file == 0x0)
        return 0;

    // bytes left and cluster index
    uint32_t bytes_left = file->file_size;
    uint32_t cluster_index = file->first_cluster_low;
    while (!eof(cluster_index) && bytes_left > 0)
    {
        bytes_left -= load_datacluster(cluster_index, dst, bytes_left);

        dst = (void *) ((uint32_t) dst + fs.csize * 512);
        cluster_index = next_cluster_index(cluster_index);
    }

    return file->file_size;
}
