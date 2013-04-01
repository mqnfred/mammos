#include <stdlib.h>


void memset(void* to_set, uint8_t value, uint32_t size)
{
    for (uint32_t i = 0; i < size; i++)
        ((char*)to_set)[i] = value;
}
