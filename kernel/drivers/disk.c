#include <drivers/disk.h>


// the main disk
// temporary
struct disk md;


static void read_partitions(void)
{
    void* dst = malloc(512);

    // setup space on the stack for the partitions entries
    md.parts = calloc(4, sizeof (struct partition));

    // read the MBR in
    disk_read(0x0, 0x1, dst);

    for (uint8_t partid = 0; partid < 4; partid += 1)
    {
        // if the system id is not set, the entry is not a valid one
        // therefore there are no more partitions to be read
        if (!*(char*)(dst + 446 + partid * 16 + 4))
            break;

        md.parts[partid].boot = !!*((char*)(dst + 446 + partid * 16 + 0));
        md.parts[partid].type = *((char*)(dst + 446 + partid * 16 + 4));
        md.parts[partid].lba = *((uint32_t*)(dst + 446 + partid * 16 + 8));
        md.parts[partid].size = *((uint32_t*)(dst + 446 + partid * 16 + 12));
    }

    free(dst);
}


static void handle_fat32(struct disk* tmp_disk, uint8_t partid)
{
    void* prout = malloc(2048);

    disk_read(tmp_disk->parts[partid].lba, 4, prout);

    free(prout);
}


void setup_disks(void)
{
    read_partitions();

    for (uint8_t partid = 0; partid < 4; partid += 1)
        if (md.parts[partid].type == FAT32)
            handle_fat32(&md, partid);
}
