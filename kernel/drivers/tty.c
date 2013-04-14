#include <drivers/tty.h>


static char* fb = (void*)0xb8000;

static uint8_t col = 0;
static uint8_t row = 0;

static const uint8_t max_rows = 25;
static const uint8_t max_cols = 80;


static void update_cursor(uint8_t r, uint8_t c)
{
    uint16_t pos = (r * max_cols) + c;

    // cursor low port to vga index register
    outb(0x3D4, 0x0F);
    outb(0x3D5, (uint8_t)(pos & 0xFF));

    // cursor high port to vga index register
    outb(0x3D4, 0x0E);
    outb(0x3D5, (uint8_t)((pos >> 8) & 0xFF));
}


static void clear(char* framebuffer)
{
    for (row = 0; row < max_rows; row += 1)
        for (col = 0; col < max_cols; col += 1)
        {
            // setup 0x0 character and light-grey on black color
            framebuffer[FB_IDX(row, col)] = 0x00;
            framebuffer[FB_IDX(row, col) + 1] = 0x07;
        }

    update_cursor(row = 0, col = 0);
}


static void slide(char* fbuf)
{
    for (uint8_t r = 0; r < max_rows - 1; r += 1)
        for (uint8_t c = 0; c < max_cols; c += 1)
        {
            fbuf[FB_IDX(r, c)] = fbuf[FB_IDX(r + 1, c)];
            fbuf[FB_IDX(r, c) + 1] = fbuf[FB_IDX(r + 1, c) + 1];
        }

    for (uint8_t c = 0; c < max_cols; c += 1)
    {
        fbuf[FB_IDX(max_rows - 1, c)] = 0;
        fbuf[FB_IDX(max_rows - 1, c) + 1] = 0;
    }
}


__attribute__((always_inline))
static inline void putc(char* framebuffer, char character, char color)
{
    if (character == '\n')
    {
        col = 0;
        row += 1;
    }
    else
    {
        framebuffer[FB_IDX(row, col)] = character;
        framebuffer[FB_IDX(row, col) + 1] = color;
        col += 1;
    }


    if (col && col % max_cols == 0)
    {
        row += 1;
        col = 0;
    }

    if (row && row % max_rows == 0)
    {
        row = max_rows - 1;
        slide(fb);
    }

    update_cursor(row, col);
}


void setup_tty(void)
{
    // clear everything!
    clear(fb);
}


void write_tty(char* src, uint32_t size)
{
    for (uint32_t i = 0; i < size; i += 1)
        putc(fb, src[i], 0x07);
}
