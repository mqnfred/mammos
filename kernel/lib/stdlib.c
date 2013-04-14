#include <lib/stdlib.h>


void memset(void* to_set, uint8_t value, uint32_t size)
{
    for (uint32_t i = 0; i < size; i++)
        ((char*)to_set)[i] = value;
}


void memcpy(void* dst, void* src, uint32_t size)
{
    for (uint32_t i = 0; i < size; i += 1)
        ((char*)dst)[i] = ((char*)src)[i];
}


uint8_t strcmp(const char* str1, const char* str2)
{
    uint32_t sum = 0;

    while (*str1 != '\0' || *str2 != '\0')
    {
        if (*str1 != '\0')
            sum += *(str1++);
        if (*str2 != '\0')
            sum -= *(str2++);

        if (sum != 0)
            break;
    }

    return sum;
}


char* strcpy(char *dest, const char* src)
{
    uint32_t i;

    for (i = 0; src[i] != '\0'; i += 1)
        dest[i] = src[i];
    dest[i] = '\0';

    return dest;
}
