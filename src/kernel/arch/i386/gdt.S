.type loadGDT, @function

loadGDT:
    mov +4(%esp), %eax  // Fetch the gdtr parameter.
    lgdt (%eax)         // Load the new GDT.

    // Reload data segments (GDT entry 2: kernel data).
    mov $0x10, %ax
    mov %ax, %ds
  	mov %ax, %es
  	mov %ax, %fs
  	mov %ax, %gs
  	mov %ax, %ss

    // Reload code segment (GDT entry 1: kernel code).
    ljmp $0x08, $1f
1:  ret

setGdt:
   mov   %ax, +4(%esp)
   MOV   [gdtr], %ax
   MOV   %eax, +8(%esp)
   MOV   [gdtr + 2], %eax
   LGDT  [gdtr]
   RET

getGdtr:
    SGDT  [gdtr]
    MOV   [gdtr], %eax
    RET

gdtr:
.word 0
.long 0

