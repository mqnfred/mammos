#include <stage2/utils/tools.h>


// the heap starts at the end of the stage 2 code
extern uint32_t stage2_end;
extern uint32_t ebda_start;
static uint32_t heap_offset = (uint32_t)&stage2_end;


// the heap is very basic and there is no way to free anything.
// the space available depends on the size of the stage 2 code, which means the
// heap can spawn between 100 and 400 kilobytes.
void *
malloc(uint32_t size)
{
    void *tmp = (void *) heap_offset;

    // considering the heap is placed above the stage2 code and below the
    // EBDA, there is a possibility of encroachment on the EBDA memory
    if (heap_offset + size > (uint32_t)&ebda_start)
        PANIC("memory", "the size of the heap encroaches on the EBDA")

    heap_offset += size;
    return tmp;
}


void *
calloc(uint32_t elts_count, uint32_t elt_size)
{
    return malloc(elt_size * elts_count);
}


uint32_t
strcmp(const char *s1, const char *s2)
{
    while ((*s1++ == *s2++) && (*s1 != '\0'));
    return s1[-1] - s2[-1];
}


uint32_t
strlen(const char *s)
{
    int len = 0;

    while (*s++ != '\0')
        len += 1;

    return len;
}


void *memcpy(void *dst, const void *src, uint32_t n)
{
    for (uint32_t i = 0; i < n; i += 1)
        ((char *) dst)[i] = ((const char *) src)[i];

    return dst;
}


char **
split(const char *src, const char sep)
{
    uint32_t chunks = 0, ptr = 0;

    // both strdup the source string and count the number of chunks - 1
    char *tmp = calloc(strlen(src) + 1, sizeof (char));
    for (uint32_t i = 0; src[i] != '\0'; i += 1)
        chunks += ((tmp[i] = src[i]) == sep ? 1 : 0);

    char *begin = tmp;

    // allocate the output char** and initialize it
    char **output = calloc(chunks + 1, sizeof (char *));
    for (uint32_t i = 0; tmp[i] != '\0'; i += 1)
    {
        if (tmp[i] != sep)
            continue;
        // do not take the first chunk (src str starts with sep
        // and ignore the case where two separators follow each others
        else if (i != 0 && *begin != sep)
            output[ptr++] = begin;

        tmp[i] = '\0';
        begin = tmp + i + 1;
    }

    // except when ending with a separator, do not forget the last chunk
    if (*begin != '\0')
        output[ptr] = begin;
    return output;
}


uint32_t
atoi(const char *str)
{
    uint8_t base = (str[0] == '0' && str[1] == 'x' ? 16 : 10);
    uint32_t sum = 0;

    for (uint32_t i = (base == 16 ? 2 : 0); str[i] != '\0'; i += 1)
        sum = sum * base + str[i] - '0';

    return sum;
}


void
perror(const char *cause, const char *msg)
{
    static uint16_t *fb = (uint16_t *) 0xB8000;
    static uint32_t fbindex = 0;

    // clean the full screen if first passage or if screen is full
    if (fbindex == 0)
        for (uint32_t i = 0 ; i < (80 * 25); i += 1)
            fb[i] = 0x0000;

    // print the file/function/bug which is the cause of the error
    for (uint32_t i = 0 ; cause[i] != '\0'; i += 1, fbindex += 1)
        fb[fbindex] = 0x0700 | cause[i];

    fb[fbindex++] = 0x0700 | ':';
    fb[fbindex++] = 0x0700 | ' ';

    // print the description of the error
    for (uint32_t i = 0 ; msg[i] != '\0'; i += 1, fbindex += 1)
        fb[fbindex] = 0x0700 | msg[i];

    // get on the next line (80 char lines)
    fbindex += 80 - (fbindex % 80);
}
