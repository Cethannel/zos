.global idt_flush
idt_flush:
	mov 4(%esp), %eax
	lidt (%eax)
	sti
	ret

// Template for the Interrupt Service Routines.
.macro isrGenerate n
    .align 4
    .type isr\n, @function
    .global isr\n

    isr\n:
        // Push a dummy error code for interrupts that don't have one.
        .if (\n != 8 && !(\n >= 10 && \n <= 14) && \n != 17)
            push $0
        .endif
        push $\n       // Push the interrupt number.
        jmp isrCommon  // Jump to the common handler.
.endmacro

.macro ISR_NOERRCODE n
	.global isr\n
	isr\n:
		CLI
		PUSH 0
		PUSH \n
		JMP isr_common_stub
.endmacro

.macro ISR_ERRCODE n
	.global isr\n
	isr\n:
		CLI
		PUSH \n
		JMP isr_common_stub
.endmacro

.macro IRQ n, a
	.global irq\n
	irq\n:
		CLI
		PUSH 0
		PUSH \a
		JMP irq_common_stub
.endmacro

ISR_NOERRCODE 0
ISR_NOERRCODE 1
ISR_NOERRCODE 2
ISR_NOERRCODE 3
ISR_NOERRCODE 4
ISR_NOERRCODE 5
ISR_NOERRCODE 6
ISR_NOERRCODE 7

ISR_ERRCODE 8
ISR_NOERRCODE 9 
ISR_ERRCODE 10
ISR_ERRCODE 11
ISR_ERRCODE 12
ISR_ERRCODE 13
ISR_ERRCODE 14
ISR_NOERRCODE 15
ISR_NOERRCODE 16
ISR_NOERRCODE 17
ISR_NOERRCODE 18
ISR_NOERRCODE 19
ISR_NOERRCODE 20
ISR_NOERRCODE 21
ISR_NOERRCODE 22
ISR_NOERRCODE 23
ISR_NOERRCODE 24
ISR_NOERRCODE 25
ISR_NOERRCODE 26
ISR_NOERRCODE 27
ISR_NOERRCODE 28
ISR_NOERRCODE 29
ISR_NOERRCODE 30
ISR_NOERRCODE 31
ISR_NOERRCODE 128
ISR_NOERRCODE 177

IRQ 0, 32
IRQ   1,    33
IRQ   2,    34
IRQ   3,    35
IRQ   4,    36
IRQ   5,    37
IRQ   6,    38
IRQ   7,    39
IRQ   8,    40
IRQ   9,    41
IRQ  10,    42
IRQ  11,    43
IRQ  12,    44
IRQ  13,    45
IRQ  14,    46
IRQ  15,    47

.extern isr_handler
isr_common_stub:
	pusha
	mov %ds, %eax
	push %eax
	mov %cr2, %eax
	push %eax

	mov $0x10, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs

	push %esp
	call isr_handler

	add $0x8, %esp
	pop %ebx
	mov %bx, %ds
	mov %bx, %es
	mov %bx, %fs
	mov %bx, %gs

	popa
	add $0x8, %esp
	sti
	iret




.extern irq_handler
irq_common_stub:
	pusha
	mov    %ds,%eax
	push   %eax
	mov    %cr2,%eax
	push   %eax
	mov    $0x10,%ax
	mov    %eax,%ds
	mov    %eax,%es
	mov    %eax,%fs
	mov    %eax,%gs
	push   %esp
	call   irq_handler
	add    $0x8,%esp
	pop    %ebx
	mov    %ebx,%ds
	mov    %ebx,%es
	mov    %ebx,%fs
	mov    %ebx,%gs
	popa
	add    $0x8,%esp
	sti
	iret
