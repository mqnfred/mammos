#ifndef STDLIB_H
# define STDLIB_H

# include <stdint.h>

# define NULL       ((void*)0x0)

# define bool       uint8_t
# define true       1
# define false      0


void memset(void* to_set, uint8_t value, uint32_t size);
void memcpy(void* dst, void* src, uint32_t size);

bool strcmp(const char* str1, const char* str2);
char* strcpy(char *dest, const char* src);


#endif // !STDLIB_H
