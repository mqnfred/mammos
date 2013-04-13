#include <stdlib.h>


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


__attribute__((always_inline))
inline void outb (uint16_t port, uint8_t value)
{
  __asm__ __volatile__ ("outb %b0, %w1" : : "a" (value), "Nd" (port));
}


__attribute__((always_inline))
inline uint8_t inb (uint16_t port)
{
    uint8_t value;
    __asm__ __volatile__ ("inb %w1, %0" : "=a" (value) : "Nd" (port));
    return value;
}
