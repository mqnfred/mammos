#include <system.h>


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
