.type loadGDT, @function
.global loadGDT
loadGDT:
    mov +4(%esp), %eax  // Fetch the gdtr parameter.
    lgdt (%eax)         // Load the new GDT.
    ret

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

.global reloadSegments

reloadSegments:
   JMP   .reload_CS
.reload_CS:
   MOV   %AX, 0x10
   MOV   %DS, %AX
   MOV   %ES, %AX
   MOV   %FS, %AX
   MOV   %GS, %AX
   MOV   %SS, %AX
   RET
