# Allocate the initial stack.
.section .bss
.align 16
stack_bottom:
.skip 16384 * 8 # 16 KiB
stack_top:

/*
The linker script specifies _start as the entry point to the kernel and the
bootloader will jump to this position once the kernel has been loaded. It
doesn't make sense to return from this function as the bootloader is gone.
*/
.section .boot
.global _start
.type _start, @function
_start:
    /*
	The bootloader has loaded us into 32-bit protected mode on a x86
	machine. Interrupts are disabled. Paging is disabled. The processor
	state is as defined in the multiboot standard. The kernel has full
	control of the CPU. The kernel can only make use of hardware features
	and any code it provides as part of itself. There's no printf
	function, unless the kernel provides its own <stdio.h> header and a
	printf implementation. There are no security restrictions, no
	safeguards, no debugging mechanisms, only what the kernel provides
	itself. It has absolute and complete power over the
	machine.
	*/
    mov $(initial_page_dir - 0xC0000000), %rcx
    mov %rcx, %cr3

    MOV %cr0, %ebx
    and ~(1 << 31), %ebx

    mov %cr4, %rcx
    or $0x10, %rcx
    mov %rcx, %cr4

    mov %cr0, %rcx
    or $0x80000000, %rcx
    //or $0x80000001, %rcx
    mov %rcx, %cr0

    mov $higher_half, %rcx
    jmp *%rcx

.section .text
higher_half:
    mov $stack_top, %esp
    push %rbx
    push %rax
    xor %ebp, %ebp
    call kmain

halt:
    hlt
    jmp halt

.section .data
.align 4096
.global initial_page_dir
initial_page_dir:
.long 0b10000011
.rept 768-1
.long 0
.endr
.long (0 << 22) | 0b10000011
.long (1 << 22) | 0b10000011
.long (2 << 22) | 0b10000011
.long (3 << 22) | 0b10000011
.rept 256-4
.long 0
.endr
