#include <stdbool.h>
#include <stdint.h>

uint16_t volatile *terminal_buffer = (uint16_t volatile *)0xB8000;

#define VGA_WIDTH 80

void terminal_putAt(uint16_t val, unsigned int x, unsigned int y) {
  const int index = y * VGA_WIDTH + x;

  terminal_buffer[index] = val;
}
