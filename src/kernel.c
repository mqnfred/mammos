#include <stdlib.h>
#include <heap.h>


__attribute__((noreturn))
void kmain(void)
{
    void* x = malloc(16);
    (void)x;

    void* y = malloc(8);
    (void)y;

    free(x);

    void* z = malloc(8);
    (void)z;

    void* a = malloc(8);
    (void)a;

    free(z);

    z = malloc(16);
    x = malloc(4096);
    z = malloc(512);
    z = malloc(8);

    free(x);
    while (1);
}
