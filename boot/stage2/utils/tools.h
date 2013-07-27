#ifndef TOOLS_H
# define TOOLS_H

# include <stdint.h>

# define PANIC(cause, msg) { perror(cause, msg); while (1); }
# define DEBUG(msg) { perror(__FILE__, msg); while (1); }


void *malloc(uint32_t size);
void *calloc(uint32_t elts_count, uint32_t elt_size);

uint32_t strcmp(const char *s1, const char *s2);
uint32_t strlen(const char *s);
void *memcpy(void *dst, const void *src, uint32_t n);

char **split(const char *path, const char sep);
uint32_t atoi(const char *str);

void perror(const char *cause, const char *msg);


#endif // !TOOLS_H
