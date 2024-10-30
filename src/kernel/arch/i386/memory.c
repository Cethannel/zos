#include <stdbool.h>
#include <stdint.h>

uint16_t volatile *terminal_buffer = (uint16_t volatile *)0xB8000;

#define VGA_WIDTH 80

void invalidate(uint32_t vaddr) { asm volatile("invlpg %0" ::"m"(vaddr)); }

void terminal_putAt(uint16_t val, unsigned int x, unsigned int y) {
  const int index = y * VGA_WIDTH + x;

  terminal_buffer[index] = val;
}

uint16_t thing[2] = {1, 2};
