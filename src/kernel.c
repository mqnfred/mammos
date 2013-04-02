#include <stdlib.h>


__attribute__((noreturn))
void kmain(void)
{
    int a = 1;
    int b = 0;
    int c = a / b;

    (void)a;
    (void)b;
    (void)c;

    while (1);
}
