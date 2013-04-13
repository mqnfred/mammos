#ifndef SYSTEM_H
# define SYSTEM_H

# include <stdint.h>


void outb (uint16_t port, uint8_t value);
uint8_t inb (uint16_t port);


#endif // !SYSTEM_H
