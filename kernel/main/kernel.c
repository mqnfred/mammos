#include <lib/stdlib.h>
#include <lib/heap.h>
#include <drivers/disk.h>
#include <drivers/tty.h>


__attribute__((noreturn))
void kmain(void)
{
    void* ptr = malloc(512);
    disk_read(0x0, 0x1, ptr);

    void* copy = malloc(1024);
    memcpy(copy, ptr, 512);

    free(ptr);
    free(copy);

    setup_tty();
    setup_disks();

    while (1);
}
