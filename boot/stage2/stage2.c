#include <stage2/stage2.h>


static const uint32_t bootflag = 0x80;
static const char* config_path = "/boot/config";


__attribute__((always_inline)) inline static uint8_t
setup_filesystem(struct part_entry *part, f_load_file *load, f_get_size *size)
{
    switch (part->system_id)
    {
        case MINIX_SYSTEM_ID:
            minix_init(part);
            *load = minix_load_file;
            *size = minix_get_size;
            return 0;
        // TODO: merge those two cases
        case FAT12_SYSTEM_ID:
            fat_init(part);
            *load = fat_load_file;
            *size = fat_get_size;
            return 0;
        case FAT16_SYSTEM_ID:
            fat_init(part);
            *load = fat_load_file;
            *size = fat_get_size;
            return 0;
    }

    return 1;
}


__attribute__((always_inline)) inline static struct part_entry *
get_partition(struct part_entry *part_table)
{
    // look for the bootable partition in the partition table (size 4)
    for (uint8_t i = 0; i < 4; i += 1)
        if (part_table[i].bootable == bootflag)
            return part_table + i;
    return 0x0;
}


__attribute__((noreturn)) __attribute__((always_inline)) inline void
stage2(struct part_entry *part_table)
{
    struct part_entry *part;
    f_load_file load;
    f_get_size size;

    // get the bootable partition structure pointer
    if ((part = get_partition(part_table)) == 0x0)
        PANIC("partition", "not bootable partition found");

    // check the filesystem and setup the load and size functions accordingly
    if (setup_filesystem(part, &load, &size))
        PANIC("filesystem", "not supported yet")

    // read the configuration file at given location
    char *config = malloc(size(config_path));
    load(config_path, config);

    // parse the configuration file and load files according to it
    char **words;
    char **lines = split(config, '\n');
    for (uint32_t i = 0; lines[i] != 0x0; i += 1)
    {
        words = split(lines[i], ' ');
        load(words[0], (void *) atoi(words[1]));
    }

    DEBUG((char *)0x100000);

    // the function is noreturn
    while (1);
}
